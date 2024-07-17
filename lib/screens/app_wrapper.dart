import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/notification_class.dart';
import '../components/notification_controller.dart';
import 'login_screen.dart';
import 'main_app_screen.dart';
import 'onboarding_screen.dart';
import 'splash_screen.dart';

class AppWrapper extends StatefulWidget {
  final String? action;
  const AppWrapper({super.key, this.action});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with TickerProviderStateMixin {
  bool _isSplashComplete = false;
  bool _isSplashVisible = true;

  @override
  void initState() {
    super.initState();
    _startFadeOutTimer();
  }

  void _startFadeOutTimer() async {
    await Future.delayed(Duration(seconds: 4));
    setState(() {
      _isSplashVisible = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => NotificationController(),
        ),
        StreamProvider<List<EleaNotification>>(
          create: (context) =>
              Provider.of<NotificationController>(context, listen: false)
                  .notificationsStream,
          initialData: [],
        ),
      ],
      child: Stack(
        children: [
          FutureBuilder<SharedPreferences>(
            future: SharedPreferences.getInstance(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                // Return a loading indicator while fetching SharedPreferences
                return const SizedBox.shrink();
              } else if (snapshot.hasError) {
                // Handle errors gracefully
                return const Text('Error fetching SharedPreferences');
              } else {
                final prefs = snapshot.data;
                if (prefs == null) {
                  // If SharedPreferences is null, navigate to OnboardingScreen
                  return const OnboardingScreen();
                }
                return StreamBuilder<User?>(
                  stream: FirebaseAuth.instance.authStateChanges(),
                  builder: (context, authSnapshot) {
                    if (authSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const SizedBox.shrink();
                    } else if (authSnapshot.hasData) {
                      final userId = authSnapshot.data!.uid;
                      final onboardingComplete =
                          prefs.getBool('$userId-onboardingComplete') ?? false;
                      NotificationController notificationController =
                          Provider.of<NotificationController>(context,
                              listen: false);
                      notificationController.setId(userId);
                      //return MainAppScreen(action: widget.action);
                      return onboardingComplete
                          ? MainAppScreen(action: widget.action)
                          : const OnboardingScreen();
                    } else {
                      return const LoginScreen();
                    }
                  },
                );
              }
            },
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _isSplashVisible ? 1.0 : 0.0,
              duration: Duration(seconds: 1),
              child: SplashScreen(),
            ),
          ),
        ],
      ),
    );
  }
}
