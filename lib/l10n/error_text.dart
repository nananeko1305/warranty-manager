import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

import 'app_localizations.dart';

/// Turns an exception into a message the user can read.
String errorText(AppLocalizations t, Object error) {
  if (error is TimeoutException || error is SocketException) {
    return t.errNoNetwork;
  }
  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-email':
        return t.errInvalidEmail;
      case 'email-already-in-use':
        return t.errEmailInUse;
      case 'weak-password':
        return t.errWeakPassword;
      case 'user-disabled':
        return t.errUserDisabled;
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return t.errWrongCredentials;
      case 'requires-recent-login':
        return t.errRecentLogin;
      case 'too-many-requests':
        return t.errTooMany;
      case 'network-request-failed':
        return t.errNoNetwork;
    }
  }
  if (error is FirebaseException) {
    switch (error.code) {
      case 'permission-denied':
        return t.errPermission;
      case 'unavailable':
        return t.errNoNetwork;
    }
  }
  return t.errGeneric;
}
