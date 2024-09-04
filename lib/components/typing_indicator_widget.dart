import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TypingIndicatorWidget extends StatefulWidget {
  final String friendId;
  final String chatId;

  TypingIndicatorWidget({required this.friendId, required this.chatId});

  @override
  _TypingIndicatorWidgetState createState() => _TypingIndicatorWidgetState();
}

class _TypingIndicatorWidgetState extends State<TypingIndicatorWidget> {
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _listenToTypingStatus();
  }

  void _listenToTypingStatus() {
    FirebaseFirestore.instance
        .collection('typing')
        .doc('${widget.friendId}_${widget.chatId}')
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        setState(() {
          _isTyping = true;
        });
      } else {
        setState(() {
          _isTyping = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isTyping ? Icon(Icons.keyboard) : SizedBox.shrink();
  }
}
