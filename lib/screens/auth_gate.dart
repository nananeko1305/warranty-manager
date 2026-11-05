import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/auth_service.dart';
import 'home_screen.dart';
import 'login_screen.dart';

/// Shows the login screen when signed out, otherwise the app.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: AuthService.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snap.data;
        if (user == null) return const LoginScreen();
        // Keyed by uid so switching accounts resets all state below.
        return HomeScreen(key: ValueKey(user.uid), uid: user.uid);
      },
    );
  }
}
