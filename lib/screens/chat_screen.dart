import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/avatar_widget.dart';
import '../components/elea_app_bar.dart';
import '../components/notification_class.dart';
import '../components/notification_controller.dart';
import 'chat_messages_screen.dart';
import '../functions.dart';
import '../text_theme_extension.dart';

class ChatScreen extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  final String? action;
  const ChatScreen({super.key, required this.userProfile, this.action});

  @override
  Widget build(BuildContext context) {
    print('chat screen: $action');
    return Scaffold(
      appBar: EleaAppBar(
        title: "Chat",
        username: userProfile["username"],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: 'Chats'),
                Tab(text: 'Friends'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ChatListPage(action: action),
                  FriendListPage(userProfile: userProfile),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ChatListPage extends StatelessWidget {
  final String? action;
  ChatListPage({super.key, this.action});

  @override
  Widget build(BuildContext context) {
    NotificationController notificationController =
        Provider.of<NotificationController>(context, listen: false);
    final currentId = FirebaseAuth.instance.currentUser?.uid;

    void openChat(String chatId) {
      showDialog(
        context: context,
        barrierDismissible:
            true, // This makes the background grey out and the dialog dismissible
        builder: (BuildContext context) {
          return ChatMessagesScreen(
            chatId: chatId,
            setCurrentScreen: (screen) {
              notificationController.setCurrentScreen(screen);
              notificationController.removeNotification(screen);
            },
          );
        },
      );
    }

    if (action != null &&
        action!.startsWith('chats') &&
        !notificationController.hasShownAction) {
      String chatId = action!.replaceFirst('chats_', '');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        openChat(chatId);
      });
      notificationController.setHasShownAction();
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("chats")
          .where("participants.${currentId}", isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return Center(child: const Text("Loading..."));
        }
        if (snapshot.data!.docs.isEmpty) {
          return Center(child: const Text("No chats here"));
        }
        List<QueryDocumentSnapshot> sortedDocs = snapshot.data!.docs;
        sortedDocs.sort((a, b) => (b['last.timestamp'] as Timestamp)
            .compareTo(a['last.timestamp'] as Timestamp));
        return ListView.builder(
          padding: EdgeInsets.only(bottom: 100.0),
          itemCount: sortedDocs.length,
          itemBuilder: (context, index) {
            DocumentSnapshot chat = sortedDocs[index];
            final friendId = Functions.firstNonMatchingItem(
                chat["participants"], currentId!);
            return FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection("users")
                  .doc(friendId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return Column(
                    children: [
                      ListTile(
                        leading: AvatarWidget(
                          userId: friendId,
                        ),
                        title: Text(
                          "■■■■■ ■■■■■",
                          style: Theme.of(context).textTheme.bodyLargeGrey,
                        ),
                        subtitle: Text("■■■ ■■■■■ ■ ■■ ■■■ ■■■ ■■■■ ■ ■■■",
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: Theme.of(context).disabledColor)),
                        trailing: Text(
                          "■■/■■/■■■■",
                        ),
                      ),
                      Container(
                        height: 1.0,
                        color: Colors.grey[300],
                      ),
                    ],
                  );
                } else {
                  final friend = snapshot.data;
                  return GestureDetector(
                    onTap: () => openChat(chat.id),
                    child: Column(
                      children: [
                        ListTile(
                          leading: StreamBuilder<List<EleaNotification>>(
                              stream:
                                  notificationController.notificationsStream,
                              builder: (context, snapshot) {
                                int badgeCount = 0;
                                if (snapshot.hasData &&
                                    snapshot.data!.isNotEmpty) {
                                  badgeCount = snapshot.data!
                                      .where((n) => n.screen
                                          .startsWith("chats_${chat.id}"))
                                      .length;
                                } else {
                                  badgeCount = notificationController
                                      .notifications
                                      .where((n) => n.screen
                                          .startsWith("chats_${chat.id}"))
                                      .length;
                                  print('badge count $badgeCount');
                                }
                                return Badge(
                                  isLabelVisible: badgeCount > 0,
                                  alignment: Alignment.topLeft,
                                  child: AvatarWidget(
                                    userId: friendId,
                                  ),
                                );
                                return AvatarWidget(
                                  userId: friendId,
                                );
                              }),
                          title: Text(
                            friend?["fullname"],
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          subtitle: Text(chat["last"]["text"],
                              maxLines: 2, overflow: TextOverflow.ellipsis),
                          trailing: Text(
                            Functions.customTimeAgo(chat["last"]["timestamp"]),
                          ),
                        ),
                        Container(
                          height: 1.0,
                          color: Colors.grey[300],
                        ),
                      ],
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}

class FriendListPage extends StatelessWidget {
  final Map<String, dynamic> userProfile;
  const FriendListPage({super.key, required this.userProfile});

  @override
  Widget build(BuildContext context) {
    NotificationController notificationController =
        Provider.of<NotificationController>(context, listen: false);
    final currentId = FirebaseAuth.instance.currentUser?.uid;
    List<String> friends = List<String>.from(userProfile['friends'] ?? []);
    return ListView.builder(
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friendId = friends[index];
        return FutureBuilder(
          future: FirebaseFirestore.instance
              .collection("users")
              .doc(friendId)
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else {
              final friend = snapshot.data!;
              return GestureDetector(
                onTap: () async {
                  String? chatId = null;
                  final chat = await FirebaseFirestore.instance
                      .collection('chats')
                      .where("participants.${currentId}", isEqualTo: true)
                      .where("participants.${friendId}", isEqualTo: true)
                      .get();
                  if (chat.docs.isNotEmpty) {
                    chatId = chat.docs.first.id;
                  } else {
                    final newChat = {
                      'owner': currentId,
                      'participants': {
                        currentId: true,
                        friendId: true,
                      },
                      'timestamp': Timestamp.now(),
                      'last': {
                        'text': 'New conversation',
                        'image': null,
                        'userId': '0',
                        'username': '',
                        'timestamp': Timestamp.now(),
                      }
                    };
                    try {
                      final newChatRef = await FirebaseFirestore.instance
                          .collection('chats')
                          .add(newChat);
                      chatId = newChatRef.id;
                    } catch (e) {}
                  }
                  if (chatId != null) {
                    if (context.mounted) {
                      showDialog(
                          context: context,
                          barrierDismissible:
                              true, // This makes the background grey out and the dialog dismissible
                          builder: (BuildContext context) {
                            return ChatMessagesScreen(
                              chatId: chatId!,
                              setCurrentScreen: (screen) {
                                notificationController.setCurrentScreen(screen);
                              },
                            );
                          });
                    }
                  }
                },
                child: Column(
                  children: [
                    ListTile(
                      leading: AvatarWidget(
                        userId: friendId,
                      ),
                      title: Text(friend['fullname'],
                          style: Theme.of(context).textTheme.bodyLarge),
                      subtitle: Text(
                        "${Functions.calculateAge(friend['dob'])} | ${friend['gender']} | ${friend['county']}, UK",
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              );
            }
          },
        );
      },
    );
  }
}
