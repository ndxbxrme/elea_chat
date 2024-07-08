import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'notification_class.dart';
import 'package:audioplayers/audioplayers.dart';

class NotificationController with ChangeNotifier {
  String? userId;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<EleaNotification> _notifications = [];
  List<String> _previousNotificationIds = [];
  final StreamController<List<EleaNotification>> _notificationStreamController =
      StreamController.broadcast();

  int _connectionsBadgeCount = 0;
  int _chatsBadgeCount = 0;
  String _currentScreen = "";
  bool _isFirstFetch = true;
  bool _isInitialized = false;
  bool _hasShownAction = false;

  AudioPlayer _audioPlayer = AudioPlayer();

  NotificationController() {}

  void _initialize() {
    _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .listen((snapshot) async {
      if (snapshot.docs.isNotEmpty) {
        _notifications = snapshot.docs
            .map((doc) => EleaNotification.fromFirestore(doc))
            .toList();
        _notificationStreamController.add(_notifications);
        print('Notifications updated:');
        print('current screen $_currentScreen');

        // Update badge counts
        _connectionsBadgeCount = _notifications
            .where((n) => n.screen.startsWith("connections"))
            .length;
        _chatsBadgeCount = _notifications
            .where((n) =>
                n.screen.startsWith("chats") && n.screen != _currentScreen)
            .length;
        int _currentScreenNotifications =
            _notifications.where((n) => n.screen == _currentScreen).length;
        if (_currentScreenNotifications > 0) {
          print('csn: $_currentScreen');
          removeNotification(_currentScreen);
        }
        // Detect new chat notifications for a different screen
        List<String> currentNotificationIds =
            _notifications.map((n) => n.id).toList();
        bool hasNewChatNotification = _notifications.any(
            (n) => n.screen.startsWith("chats") && n.screen != _currentScreen);
        print(
            'has new chat: $hasNewChatNotification, first fetch: $_isFirstFetch');
        if (hasNewChatNotification && !_isFirstFetch) {
          await _playNotificationSound();
        }
        _isFirstFetch = false;

        // Update previous notification IDs
        _previousNotificationIds = currentNotificationIds;
      } else {
        print('No notifications found.');
        _notifications = [];
        _notificationStreamController.add([]);
        _connectionsBadgeCount = 0;
        _chatsBadgeCount = 0;
      }
      notifyListeners();
    }, onError: (error) {
      print('Error fetching notifications: $error');
      _notificationStreamController.addError(error);
    });
  }

  Future<void> _playNotificationSound() async {
    try {
      print('playing notification');
      await _audioPlayer.play(AssetSource('sounds/notification_sound2.wav'));
    } catch (e) {
      print('Error playing notification sound: $e');
    }
  }

  Stream<List<EleaNotification>> get notificationsStream =>
      _notificationStreamController.stream;

  int get connectionsBadgeCount => _connectionsBadgeCount;
  int get chatsBadgeCount => _chatsBadgeCount;
  bool get hasShownAction => _hasShownAction;
  List<EleaNotification> get notifications => _notifications;

  void removeNotification(String screen) {
    print('screen, $screen - current screen $_currentScreen');
    _notifications
        .where((notification) => notification.screen.startsWith(screen))
        .forEach((notification) {
      _firestore.collection('notifications').doc(notification.id).delete();
    });
  }

  void setCurrentScreen(String screen) {
    print('set current screen, $screen');
    _currentScreen = screen;
  }

  void setHasShownAction() {
    _hasShownAction = true;
  }

  void setId(String userId) {
    this.userId = userId;
    if (!_isInitialized) {
      _initialize();
    }
    _isInitialized = true;
  }

  @override
  void dispose() {
    _notificationStreamController.close();
    super.dispose();
  }
}
