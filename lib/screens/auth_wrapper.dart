import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'error_screen.dart';
import 'loading_screen.dart';
import 'login_screen.dart';
import 'user_profile_loader.dart';

class AuthWrapper extends StatelessWidget {
  final String? action;

  const AuthWrapper({required this.action});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return LoadingScreen();
        } else if (authSnapshot.hasError) {
          return ErrorScreen(message: 'Error: ${authSnapshot.error}');
        } else if (authSnapshot.hasData) {
          return UserProfileLoader(
            action: action,
            userId: authSnapshot.data!.uid,
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
