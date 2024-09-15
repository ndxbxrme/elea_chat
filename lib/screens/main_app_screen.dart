import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
//import 'package:badges/badges.dart';

import '../components/notification_class.dart';
import '../components/notification_controller.dart';
import 'chat_screen.dart';
import 'connections_screen.dart';
import 'foryou_screen.dart';

class MainAppScreen extends StatefulWidget {
  final String? action;
  final Map<String, dynamic> userProfile;
  const MainAppScreen({super.key, this.action, required this.userProfile});

  @override
  // ignore: library_private_types_in_public_api
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  late ValueNotifier<int> _connectionsCountNotifier;
  late ValueNotifier<int> _chatsCountNotifier;
  late StreamSubscription<List<EleaNotification>> _subscription;
  int _currentIndex = 0;
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _onTap(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onPopInvoked(bool didPop) async {
    final isFirstRouteInCurrentTab =
        !await _navigatorKeys[_currentIndex].currentState!.maybePop();
    if (isFirstRouteInCurrentTab) {
      if (_currentIndex != 0) {
        _onTap(0);
      } else {
        didPop = false;
      }
    } else {
      didPop = true;
    }
  }

  @override
  void initState() {
    super.initState();
    _connectionsCountNotifier = ValueNotifier<int>(0);
    _chatsCountNotifier = ValueNotifier<int>(0);

    // Fetch initial badge count
    NotificationController notificationController =
        Provider.of<NotificationController>(context, listen: false);
    _connectionsCountNotifier.value =
        notificationController.connectionsBadgeCount;
    _chatsCountNotifier.value = notificationController.chatsBadgeCount;

    // Listen for badge count updates
    _subscription =
        notificationController.notificationsStream.listen((notifications) {
      if (mounted) {
        int connectionsCount = notifications
            .where((n) => n.screen.startsWith("connections"))
            .length;
        _connectionsCountNotifier.value = connectionsCount;
        int chatsCount =
            notifications.where((n) => n.screen.startsWith("chats")).length;
        _chatsCountNotifier.value = chatsCount;
      }
    });

    if (widget.action != null && !notificationController.hasShownAction) {
      if (widget.action!.startsWith('chats')) {
        _currentIndex = 2;
      }
      if (widget.action!.startsWith('forum')) {
        _currentIndex = 0;
      }
    }
  }

  @override
  void dispose() {
    _subscription.cancel();
    _connectionsCountNotifier.dispose();
    _chatsCountNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: _onPopInvoked,
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: <Widget>[
                _buildNavigator(0, widget.userProfile),
                _buildNavigator(1, widget.userProfile),
                _buildNavigator(2, widget.userProfile),
              ],
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: IgnorePointer(
                child: Container(
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment(0.00, -1.00),
                      end: Alignment(0, 1),
                      colors: [
                        Colors.white.withOpacity(0.3400000035762787),
                        Color(0xFFF4EEEA)
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      backgroundColor: Color(0xFFF4EEEA),
      currentIndex: _currentIndex,
      onTap: _onTap,
      items: [
        BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome), label: 'For You'),
        BottomNavigationBarItem(
          icon: ValueListenableBuilder<int>(
              valueListenable: _connectionsCountNotifier,
              builder: (context, badgeCount, snapshot) {
                return Badge(
                  isLabelVisible: badgeCount > 0,
                  label: Text(
                    '$badgeCount',
                    style: TextStyle(color: Colors.white),
                  ),
                  alignment: Alignment.topRight,
                  offset: Offset(15, -10),
                  backgroundColor: Colors.red,
                  child: Icon(Icons.groups_outlined),
                );
              }),
          label: 'Connections',
        ),
        BottomNavigationBarItem(
          icon: ValueListenableBuilder<int>(
              valueListenable: _chatsCountNotifier,
              builder: (context, badgeCount, snapshot) {
                return Badge(
                  isLabelVisible: badgeCount > 0,
                  label: Text(
                    '$badgeCount',
                    style: TextStyle(color: Colors.white),
                  ),
                  alignment: Alignment.topRight,
                  offset: Offset(15, -10),
                  backgroundColor: Colors.red,
                  child: Icon(Icons.mail_outline),
                );
              }),
          label: 'Chat',
        ),
      ],
    );
  }

  Widget _buildNavigator(int index, Map<String, dynamic> userProfile) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) {
            if (index == 0) {
              return ForYouScreen(
                userProfile: userProfile,
                action: widget.action,
              );
            } else if (index == 1) {
              return ConnectionsScreen(
                userProfile: userProfile,
              );
            } else {
              return ChatScreen(
                userProfile: userProfile,
                action: widget.action,
              );
            }
          },
        );
      },
    );
  }
}
