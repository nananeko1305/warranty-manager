import 'package:firebase_auth/firebase_auth.dart';

import 'push_service.dart';

/// Email + password accounts through Firebase Auth.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register(String email, String password) async {
    await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  /// Firebase requires a recent sign-in to change the password, so the
  /// user confirms the current one first.
  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final user = _auth.currentUser!;
    await reauthenticate(user, currentPassword);
    await user.updatePassword(newPassword);
  }

  Future<void> reauthenticate(User user, String password) =>
      user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );

  /// Reminders name what the owner bought, so they must stop reaching this
  /// phone. Each step is best effort and nothing may stand in the way of
  /// signing out.
  Future<void> signOut() async {
    await PushService.instance.forgetToken();
    await _auth.signOut();
    await PushService.instance.dropToken();
  }
}
