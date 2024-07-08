import 'package:flutter/material.dart';

class ChatDateWidget extends StatelessWidget {
  final DateTime date;

  const ChatDateWidget({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final difference = now.difference(date);

    String timeAgo;
    if (difference.inDays >= 365) {
      timeAgo = '${(difference.inDays / 365).floor()}y';
    } else if (difference.inDays >= 30) {
      timeAgo = '${(difference.inDays / 30).floor()}m';
    } else if (difference.inDays >= 7) {
      timeAgo = '${(difference.inDays / 7).floor()}w';
    } else if (difference.inDays >= 1) {
      timeAgo = '${difference.inDays}d';
    } else if (difference.inHours >= 1) {
      timeAgo = '${difference.inHours}h';
    } else if (difference.inMinutes >= 1) {
      timeAgo = '${difference.inMinutes}m';
    } else {
      timeAgo = '${difference.inSeconds}s';
    }

    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            timeAgo,
            style: TextStyle(
              fontSize: 14.0,
              color: Colors.grey[500],
            ),
          ),
        ),
      ),
    );
  }
}
