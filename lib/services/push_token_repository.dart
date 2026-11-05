import 'package:cloud_firestore/cloud_firestore.dart';

/// Which account each phone belongs to, in `pushTokens/{token}`, so the
/// push worker reaches accounts and not installs. The token is the id, so
/// a phone belongs to whoever signed in on it last.
class PushTokenRepository {
  PushTokenRepository._();
  static final PushTokenRepository instance = PushTokenRepository._();

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _tokens =>
      _db.collection('pushTokens');

  Future<void> save(String token, String uid) =>
      _tokens.doc(token).set({'uid': uid});

  Future<void> delete(String token) => _tokens.doc(token).delete();
}
