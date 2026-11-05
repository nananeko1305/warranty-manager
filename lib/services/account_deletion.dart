import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_service.dart';
import 'push_service.dart';
import 'receipt_cleanup.dart';
import 'saved_emails.dart';

/// Deletes the signed-in account and everything it owns in Firestore.
///
/// Data goes before the account, because the rules need the sign-in. It waits
/// for answers, unlike every other write in the app, and refuses to go on
/// offline: this cannot be finished later. If it fails halfway the account
/// still exists, and trying again carries on with what is left.
class AccountDeletion {
  AccountDeletion._();
  static final AccountDeletion instance = AccountDeletion._();

  static const _timeout = Duration(seconds: 20);

  /// A batch takes 500 writes at most.
  static const _batchSize = 400;

  static const _releasesAtOnce = 5;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> delete(String password) async {
    final user = FirebaseAuth.instance.currentUser!;
    final email = user.email;
    // Fails fast when offline, and proves it is really the owner.
    await AuthService.instance.reauthenticate(user, password);
    // Saves still queued here must not recreate what is about to be deleted.
    await _db.waitForPendingWrites().timeout(_timeout);
    await _releasePhotos(user.uid);
    await _deleteAll(_db.collection('warranties'), 'ownerId', user.uid);
    // Tokens too: the account's other phones are not in this phone's cache.
    await _deleteAll(_db.collection('pushTokens'), 'uid', user.uid);
    await user.delete();
    await PushService.instance.dropToken();
    if (email != null) await SavedEmails.instance.remove(email);
  }

  /// A few at a time, and best effort: a photo left behind must not stop someone
  /// from deleting their account.
  Future<void> _releasePhotos(String uid) async {
    final snap = await _db
        .collection('warranties')
        .where('ownerId', isEqualTo: uid)
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    final ids = [
      for (final doc in snap.docs)
        if ((doc.data()['receiptUrl'] as String? ?? '').isNotEmpty) doc.id,
    ];
    for (var i = 0; i < ids.length; i += _releasesAtOnce) {
      await Future.wait(
        ids.skip(i).take(_releasesAtOnce).map(ReceiptCleanup.instance.release),
      );
    }
  }

  /// From the server, since the cache knows only what this phone has seen.
  Future<void> _deleteAll(
    CollectionReference<Map<String, dynamic>> collection,
    String field,
    String uid,
  ) async {
    final snap = await collection
        .where(field, isEqualTo: uid)
        .get(const GetOptions(source: Source.server))
        .timeout(_timeout);
    final docs = snap.docs;
    for (var i = 0; i < docs.length; i += _batchSize) {
      final batch = _db.batch();
      for (final doc in docs.skip(i).take(_batchSize)) {
        batch.delete(doc.reference);
      }
      await batch.commit().timeout(_timeout);
    }
  }
}
