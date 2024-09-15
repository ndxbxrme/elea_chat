import 'package:flutter/material.dart';
import '../constants.dart';
import '../functions.dart';
import 'avatar_widget.dart';
import 'expandable_text.dart';
import '../text_theme_extension.dart';

class SuggestedConnection extends StatelessWidget {
  final Map<String, dynamic> user;
  final Function()? dismissedPressed;
  final Function()? connectPressed;
  const SuggestedConnection({
    super.key,
    required this.user,
    this.dismissedPressed,
    this.connectPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: AvatarWidget(
            userId: user["id"],
          ),
          title: Text(user['fullname'],
              style: user["id"] == "null"
                  ? Theme.of(context).textTheme.bodyLargeGrey
                  : Theme.of(context).textTheme.bodyLarge),
          subtitle: Text(
            "${Functions.calculateAge(user['dob'])} | ${user['gender']} | ${user['county']}, UK",
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: user["id"] == "null"
              ? Text(user['bio'],
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLargeGrey.color))
              : ExpandableText(user['bio'] != null ? user['bio'] : "",
                  maxLines: 4),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                  style: Constants.outlineButtonStyle,
                  onPressed: dismissedPressed,
                  child: Text("Dismiss")),
              TextButton(
                  style: Constants.orangeButtonStyle,
                  onPressed: connectPressed,
                  child: Text("Request to connect")),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Container(
            height: 1,
            color: Colors.grey[300],
          ),
        ),
      ],
    );
  }
}
