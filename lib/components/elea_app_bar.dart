import 'package:elea_chat/components/notification_controller.dart';
import 'package:elea_chat/screens/new_forum_post_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/profile_screen.dart';
import 'avatar_widget.dart';
import 'notification_class.dart';

class EleaAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final String userId = FirebaseAuth.instance.currentUser!.uid;
  final String username;
  final Map<String, dynamic>? userProfile;
  final bool canMakeNewPost;

  EleaAppBar({
    required this.title,
    this.actions,
    this.username = "",
    this.userProfile,
    this.canMakeNewPost = false,
  });

  @override
  Widget build(BuildContext context) {
    final NotificationController notificationController =
        Provider.of<NotificationController>(context, listen: false);

    return AppBar(
      title: Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      centerTitle: true, // Ensure title is centered
      actions: [
        if (canMakeNewPost)
          IconButton(
            icon: Image.asset(
              'assets/images/pencil.png',
              width: 24, // Adjust size as needed
              height: 24,
            ),
            onPressed: () {
              showDialog(
                context: context,
                barrierDismissible: true,
                builder: (BuildContext context) {
                  return Dialog(
                    child: NewForumPostScreen(
                      username: username,
                    ),
                  );
                },
              );
            },
          ),
        PopupMenuButton<String>(
          onSelected: (String result) {
            switch (result) {
              case 'My profile':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileScreen(
                      userId: userId,
                      myProfile: userProfile,
                    ),
                  ),
                );
                break;
              case 'Log out':
                FirebaseAuth.instance.signOut();
                break;
            }
          },
          itemBuilder: (BuildContext context) => [
            PopupMenuItem<String>(
              value: 'My profile',
              child: Text('My profile'),
            ),
            PopupMenuItem<String>(
              value: 'Log out',
              child: Text('Log out'),
            ),
          ],
          child: StreamBuilder<List<EleaNotification>>(
              stream: notificationController.notificationsStream,
              builder: (context, snapshot) {
                return Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Badge(
                    alignment: Alignment.bottomLeft,
                    isLabelVisible: userProfile?["avatarUrl"] == null ||
                        userProfile?["bio"] == null,
                    child: AvatarWidget(
                      userId: userId,
                      currentRandom: userProfile?["rnd"] ?? 0,
                    ),
                  ),
                );
              }),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
