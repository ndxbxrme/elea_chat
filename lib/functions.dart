import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'components/avatar_widget.dart';

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

  static void showConnectionRequestPopup(
    BuildContext context,
    Map<String, dynamic> user,
  ) {
    showDialog(
      context: context,
      barrierDismissible:
          true, // This makes the background grey out and the dialog dismissible
      builder: (BuildContext context) {
        String post = "";
        return Dialog(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.all(0.0),
                title: Center(child: Text("Connection Request")),
                leading: SizedBox(width: 24.0),
                trailing: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              ListTile(
                leading: AvatarWidget(
                  userId: user["id"],
                ),
                title: Text(user['fullname'],
                    style: Theme.of(context).textTheme.bodyLarge),
                subtitle: Text(
                  "${Functions.calculateAge(user['dob'])} | ${user['gender']} | ${user['county']}, UK",
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  maxLines: 10,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) => post = value,
                ),
              ),
              Padding(
                padding: EdgeInsets.all(16.0),
                child: TextButton(
                  onPressed: () async {
                    if (!post.isEmpty) {
                      final String? fromId =
                          FirebaseAuth.instance.currentUser?.uid;
                      final String? toId = user['id'];
                      final fromUserRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(fromId);
                      final fromUser = await fromUserRef.get();
                      final toUserRef = FirebaseFirestore.instance
                          .collection('users')
                          .doc(toId);
                      final toUser = await toUserRef.get();
                      if (fromUser.exists && toUser.exists) {
                        List<dynamic> outgoing =
                            fromUser.data()?['outgoing'] ?? [];
                        if (!outgoing.contains(toId)) {
                          outgoing.add(toId);
                          await fromUserRef.update({'outgoing': outgoing});
                        }
                        List<dynamic> incoming =
                            toUser.data()?['incoming'] ?? [];
                        if (!incoming.contains(fromId)) {
                          incoming.add(fromId);
                          await toUserRef.update({'incoming': incoming});
                        }
                      }
                      try {
                        // Reference to the Firestore collection
                        final collectionRef = FirebaseFirestore.instance
                            .collection('connectionRequests');
                        // Create the object
                        Map<String, dynamic> postObject = {
                          'from': fromId,
                          'to': toId,
                          'post': post,
                          'timestamp': FieldValue
                              .serverTimestamp() // optional: add timestamp
                        };
                        // Add the object to the collection
                        await collectionRef.add(postObject);
                        final notificationRef = FirebaseFirestore.instance
                            .collection('notifications');
                        Map<String, dynamic> notificationObject = {
                          'userId': toId,
                          'screen': 'connections_$fromId',
                          'timestamp': FieldValue.serverTimestamp(),
                        };
                        Functions.showToast("Connection request sent.");
                        notificationRef.add(notificationObject);
                      } catch (e) {
                        print('Failed to add request: $e');
                      }
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text("Send"),
                ),
              )
            ],
          ),
        );
      },
    );
  }

  static void sharePost(String title, String content, String url) {
    String textToShare = "$title\n\n$content\n\nRead more at: $url";
    Share.share(textToShare);
  }
}
