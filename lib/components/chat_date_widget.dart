import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ChatDateWidget extends StatelessWidget {
  final DateTime date;

  const ChatDateWidget({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            DateFormat('d MMMM').format(date),
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
