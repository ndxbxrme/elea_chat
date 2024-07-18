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
  EleaAppBar({
    required this.title,
    this.actions,
    this.username = "",
    this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    final NotificationController notificationController =
        Provider.of<NotificationController>(context, listen: false);
    return Scaffold(
      body: Stack(
        children: [
          AppBar(
            actions: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.post_add),
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
                            return Badge(
                              alignment: Alignment.bottomLeft,
                              isLabelVisible:
                                  userProfile?["avatarUrl"] == null ||
                                      userProfile?["bio"] == null,
                              child: AvatarWidget(
                                userId: userId,
                                currentRandom: userProfile?["rnd"],
                              ),
                            );
                          }),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            children: [
              SizedBox(height: 40.0),
              Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
