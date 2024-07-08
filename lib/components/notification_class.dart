import 'package:cloud_firestore/cloud_firestore.dart';

class EleaNotification {
  final String id;
  final String userId;
  final String screen;
  final Timestamp timestamp;

  EleaNotification(
      {required this.id,
      required this.userId,
      required this.screen,
      required this.timestamp});

  factory EleaNotification.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map;
    return EleaNotification(
      id: doc.id,
      userId: data['userId'],
      screen: data['screen'],
      timestamp: data['timestamp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'screen': screen,
      'timestamp': timestamp,
    };
  }
}
