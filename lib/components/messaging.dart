import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../app_router.dart';

FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(); // Ensure Firebase is initialized
  print('Handling a background message: ${message.notification?.title}');
}

void _showNotification(RemoteMessage message) {
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'high_importance_channel',
    'High Importance Notifications',
    channelDescription: 'This channel is used for important notifications.',
    importance: Importance.max,
    priority: Priority.high,
    showWhen: false,
  );

  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);

  flutterLocalNotificationsPlugin.show(
    0,
    message.notification?.title,
    message.notification?.body,
    platformChannelSpecifics,
  );
}

Future<void> _cleanupOldTokens(String userId) async {
  DocumentReference userRef =
      FirebaseFirestore.instance.collection('users').doc(userId);
  QuerySnapshot tokenSnapshot = await userRef
      .collection('tokens')
      .where('createdAt',
          isLessThan:
              Timestamp.fromDate(DateTime.now().subtract(Duration(days: 30))))
      .get();

  for (DocumentSnapshot doc in tokenSnapshot.docs) {
    await doc.reference.delete();
  }
}

Future<void> _saveTokenToDatabase(String userId, String token) async {
  DocumentReference userRef =
      FirebaseFirestore.instance.collection('users').doc(userId);
  DocumentReference tokenRef = userRef.collection('tokens').doc(token);

  // Check if the token is already in the database
  DocumentSnapshot tokenDoc = await tokenRef.get();

  if (!tokenDoc.exists) {
    // If the token does not exist, add it to the user's tokens subcollection
    await tokenRef.set({
      'token': token,
      'createdAt': FieldValue.serverTimestamp(),
      'platform': Platform.operatingSystem,
    });
  } else {
    // Optionally, you can update the timestamp if the token already exists
    await tokenRef.update({
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}

void _handleMessage(RemoteMessage message) {
  if (message.data.containsKey('chatId')) {
    final chatId = message.data['chatId'];
    router.go('/main/chats_$chatId');
  }
  if (message.data.containsKey('postId')) {
    final postId = message.data['postId'];
    router.go('/main/forum_$postId');
  }
}

class Messaging {
  static Future<void> setupFirebaseMessaging(String userId) async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Request permission for iOS (and other platforms if needed)
    NotificationSettings settings = await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Obtain the FCM token
    String? token = await messaging.getToken();
    if (token != null) {
      await _saveTokenToDatabase(userId, token);
      await _cleanupOldTokens(userId);
    }
    print("FCM Token: $token");

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Message received in foreground: ${message.notification?.title}');
      _showNotification(message);
    });

    // Handle when the app is opened from a terminated state
    FirebaseMessaging.instance.getInitialMessage().then((message) {
      if (message != null) {
        print(
            'App opened from terminated state by a message: ${message.notification?.title}');
        // Handle navigation or any other action based on the notification
        _handleMessage(message);
      }
    });

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await _saveTokenToDatabase(userId, newToken);
    });
    // Handle when the app is opened from background state by a message
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print(
          'App opened from background by a message: ${message.notification?.title}');
      // Handle navigation or any other action based on the notification
      _handleMessage(message);
    });

    // Initialize flutter_local_notifications
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }
}
