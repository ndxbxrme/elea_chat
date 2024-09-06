import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

//import '../components/messaging.dart';
import 'error_screen.dart';
import 'loading_screen.dart';
import 'main_app_screen.dart';
import 'onboarding_screen.dart';

class UserProfileLoader extends StatelessWidget {
  final String? action;
  final String userId;

  const UserProfileLoader({required this.action, required this.userId});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      future: FirebaseFirestore.instance.collection("users").doc(userId).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return LoadingScreen();
        } else if (snapshot.hasError) {
          return ErrorScreen(message: 'Error: ${snapshot.error}');
        } else if (!snapshot.hasData || snapshot.data?.data() == null) {
          return const OnboardingScreen();
        } else {
          final userProfile = snapshot.data!.data()!;
          userProfile["id"] = userId;
          //Messaging.setupFirebaseMessaging(userId);

          final Random random = Random();
          userProfile["rnd"] = random.nextInt(999999);

          return MainAppScreen(action: action, userProfile: userProfile);
        }
      },
    );
  }
}
