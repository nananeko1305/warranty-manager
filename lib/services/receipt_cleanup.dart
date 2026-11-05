import 'dart:async';
import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// The push worker, which holds the Cloudinary secret that cannot ship in an APK.
final Uri kReleaseReceiptUrl = Uri.parse(
  'https://warranty-manager-push.warranty-manager-push.workers.dev/release-receipt',
);

/// Asks the push worker to delete the photo on a warranty, while the warranty still
/// says which one it is. The worker reads the photo off the warranty and checks
/// whose it is, so this only has to name the warranty.
class ReceiptCleanup {
  ReceiptCleanup({http.Client? client, Future<String?> Function()? idToken})
    : _client = client ?? http.Client(),
      _idToken = idToken ?? _currentIdToken;

  static final ReceiptCleanup instance = ReceiptCleanup();

  static const _timeout = Duration(seconds: 8);

  final http.Client _client;
  final Future<String?> Function() _idToken;

  static Future<String?> _currentIdToken() async =>
      FirebaseAuth.instance.currentUser?.getIdToken();

  /// Whether the photo is taken care of. Never throws and waits only briefly:
  /// offline the photo stays behind, which must not stop anyone from deleting a
  /// warranty.
  Future<bool> release(String warrantyId) async {
    try {
      final token = await _idToken().timeout(_timeout);
      if (token == null) return false;
      final response = await _client
          .post(
            kReleaseReceiptUrl,
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'warrantyId': warrantyId}),
          )
          .timeout(_timeout);
      return response.statusCode == 204;
    } catch (_) {
      return false;
    }
  }
}
