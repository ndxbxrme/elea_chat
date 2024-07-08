import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

class Functions {
  static void showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  static String calculateAge(String dateOfBirth) {
    try {
      // Define the date format
      final DateFormat dateFormat = DateFormat('dd/MM/yyyy');

      // Parse the input date string to a DateTime object
      DateTime birthDate = dateFormat.parse(dateOfBirth);

      // Get the current date
      DateTime today = DateTime.now();

      // Calculate the age
      int age = today.year - birthDate.year;

      // Adjust age if the birth date has not yet occurred this year
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age.toString();
    } catch (e) {
      return "■■";
    }
  }

  static String firstNonMatchingItem(Map<String, dynamic> ids, String myId) {
    for (String id in ids.keys) {
      if (id != myId) {
        return id;
      }
    }
    return "unknown"; // or throw an exception if you prefer
  }

  static String customTimeAgo(Timestamp timestamp) {
    DateTime now = DateTime.now();
    DateTime date = timestamp.toDate();

    Duration difference = now.difference(date);

    if (difference.inDays == 0) {
      // Today
      return DateFormat('HH:mm').format(date);
    } else if (difference.inDays == 1) {
      // Yesterday
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      // Last 7 days
      return DateFormat('EEEE')
          .format(date); // returns day name, e.g., 'Thursday'
    } else {
      // Older than 7 days
      return DateFormat('dd/MM/yyyy').format(date);
    }
  }

  static String formatDate(Timestamp ts) {
    DateTime date = ts.toDate();
    return timeago.format(date, locale: 'en');
  }
}
