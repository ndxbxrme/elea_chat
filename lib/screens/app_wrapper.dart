import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../components/notification_class.dart';
import '../components/notification_controller.dart';
//import '../components/messaging.dart';
import 'auth_wrapper.dart';
import 'error_screen.dart';
import 'loading_screen.dart';
import 'onboarding_screen.dart';
import 'splash_screen.dart';

class AppWrapper extends StatefulWidget {
  final String? action;
  const AppWrapper({super.key, this.action});

  @override
  State<AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<AppWrapper> with TickerProviderStateMixin {
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
                return LoadingScreen();
              } else if (snapshot.hasError) {
                return ErrorScreen(message: 'Error fetching SharedPreferences');
              } else {
                final prefs = snapshot.data;
                if (prefs == null) {
                  return const OnboardingScreen();
                }
                return AuthWrapper(action: widget.action);
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
