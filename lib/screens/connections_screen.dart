import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../components/avatar_widget.dart';
import '../components/custom_badge_tab.dart';
import '../components/elea_app_bar.dart';
import '../components/expandable_text.dart';
import '../components/notification_class.dart';
import '../components/notification_controller.dart';
import '../components/suggested_connection_widget.dart';
import '../constants.dart';
import '../functions.dart';

Future<Map<String, Map<String, dynamic>>> getMatchedUsers(
    Map<String, dynamic> userProfile) async {
  Map<String, Map<String, dynamic>> matchedUsers = {};
  List<String> usersToIgnore = [FirebaseAuth.instance.currentUser?.uid ?? ''];
  List<String> incoming = List<String>.from(userProfile['incoming'] ?? []);
  for (String id in incoming) {
    if (!usersToIgnore.contains(id)) {
      usersToIgnore.add(id);
    }
  }
  List<String> outgoing = List<String>.from(userProfile['outgoing'] ?? []);
  for (String id in outgoing) {
    if (!usersToIgnore.contains(id)) {
      usersToIgnore.add(id);
    }
  }
  List<String> dismissed = List<String>.from(userProfile['dismissed'] ?? []);
  for (String id in dismissed) {
    if (!usersToIgnore.contains(id)) {
      usersToIgnore.add(id);
    }
  }
  List<String> blocked = List<String>.from(userProfile['blocked'] ?? []);
  for (String id in blocked) {
    if (!usersToIgnore.contains(id)) {
      usersToIgnore.add(id);
    }
  }
  List<String> friends = List<String>.from(userProfile['friends'] ?? []);
  for (String id in friends) {
    if (!usersToIgnore.contains(id)) {
      usersToIgnore.add(id);
    }
  }
  List<String> topics = List<String>.from(userProfile['topics'] ?? []);
  for (String topic in topics) {
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('topics', arrayContains: topic)
        .get();

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> userData = doc.data() as Map<String, dynamic>;
      if (!usersToIgnore.contains(doc.id)) {
        userData["id"] = doc.id;
        matchedUsers[doc.id] = userData;
      }
    }
  }

  return matchedUsers;
}

List<Map<String, dynamic>> scoreAndSortUsers(
    Map<String, Map<String, dynamic>> usersMap,
    Map<String, dynamic> userProfile) {
  List<Map<String, dynamic>> users = usersMap.values.toList();

  users.forEach((user) {
    int score = 0;
    List<String> userTopics = List<String>.from(user['topics']);
    List<String> topics = List<String>.from(userProfile['topics'] ?? []);
    for (String topic in topics) {
      if (userTopics.contains(topic)) {
        score++;
      }
    }

    if (user['county'] == userProfile['county']) {
      score += 2;
    }

    user['score'] = score;
  });

  users.sort((a, b) => b['score'].compareTo(a['score']));

  return users;
}

Stream<List<Map<String, dynamic>>> getConnectionRequests(
    Map<String, dynamic> userProfile) async* {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  List<String> usersToIgnore = [userId ?? ''];
  List<String> incoming = List<String>.from(userProfile['friends'] ?? []);
  List<String> dismissed = List<String>.from(userProfile['dismissed'] ?? []);
  List<String> blocked = List<String>.from(userProfile['blocked'] ?? []);

  usersToIgnore.addAll(incoming.where((id) => !usersToIgnore.contains(id)));
  usersToIgnore.addAll(dismissed.where((id) => !usersToIgnore.contains(id)));
  usersToIgnore.addAll(blocked.where((id) => !usersToIgnore.contains(id)));

  yield* FirebaseFirestore.instance
      .collection('connectionRequests')
      .where('to', isEqualTo: userId)
      .snapshots()
      .map((querySnapshot) {
    List<Map<String, dynamic>> matchedRequests = [];
    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> connectionData = doc.data() as Map<String, dynamic>;
      if (!usersToIgnore.contains(connectionData["from"])) {
        connectionData["id"] = doc.id;
        matchedRequests.add(connectionData);
      }
    }
    return matchedRequests;
  });
}

void _showPopup(BuildContext context, Map<String, dynamic> user) {
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
                      List<dynamic> incoming = toUser.data()?['incoming'] ?? [];
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

class ConnectionsScreen extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const ConnectionsScreen({
    super.key,
    required this.userProfile,
  });

  @override
  _ConnectionsScreenState createState() => _ConnectionsScreenState();
}

class _ConnectionsScreenState extends State<ConnectionsScreen> {
  late ValueNotifier<int> _badgeCountNotifier;
  late StreamSubscription<List<EleaNotification>> _subscription;
  late NotificationController notificationController;

  @override
  void initState() {
    super.initState();
    _badgeCountNotifier = ValueNotifier<int>(0);

    // Fetch initial badge count
    notificationController =
        Provider.of<NotificationController>(context, listen: false);
    _badgeCountNotifier.value = notificationController.connectionsBadgeCount;

    // Listen for badge count updates
    _subscription =
        notificationController.notificationsStream.listen((notifications) {
      if (mounted) {
        int connectionsCount = notifications
            .where((n) => n.screen.startsWith("connections"))
            .length;
        _badgeCountNotifier.value = connectionsCount;
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    _badgeCountNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EleaAppBar(
        title: "Connections",
        username: widget.userProfile["username"],
      ),
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            TabBar(
              tabs: [
                Tab(text: 'Suggested Connections'),
                ValueListenableBuilder<int>(
                  valueListenable: _badgeCountNotifier,
                  builder: (context, badgeCount, child) {
                    return CustomBadgeTab(
                      text: 'Connection Requests',
                      badgeCount: badgeCount,
                    );
                  },
                ),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  SuggestedConnectionsPage(
                    userProfile: widget.userProfile,
                  ),
                  ConnectionRequestsPage(
                    userProfile: widget.userProfile,
                    notificationController: notificationController,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildTabBar(
    BuildContext context, NotificationController notificationController) {
  return TabBar(
    tabs: [
      Tab(text: 'Suggested Connections'),
      Tab(
        child: StreamBuilder<List<EleaNotification>>(
          stream: notificationController.notificationsStream,
          builder: (context, snapshot) {
            int connectionsCount = 0;
            if (snapshot.hasData) {
              List<EleaNotification> notifications = snapshot.data!;
              connectionsCount = notifications
                  .where((n) => n.screen.startsWith("connections"))
                  .length;
            }
            return CustomBadgeTab(
              text: 'Connection Requests',
              badgeCount: connectionsCount,
            );
          },
        ),
      ),
    ],
  );
}

class SuggestedConnectionsPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  const SuggestedConnectionsPage({
    super.key,
    required this.userProfile,
  });

  @override
  State<SuggestedConnectionsPage> createState() =>
      _SuggestedConnectionsPageState();
}

class _SuggestedConnectionsPageState extends State<SuggestedConnectionsPage> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: getMatchedUsers(widget.userProfile),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SuggestedConnection(
            user: {
              "id": "null",
              "fullname": "■■■■■ ■■■■",
              "dob": "■■",
              "gender": "■■■■",
              "county": "■■■ ■■■■",
              "bio": "■■ ■■■■■ ■■ ■■■■ ■ ■■■ ■■■ ■ ■ ■■■■ ■ ■■",
            },
          );
        } else if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        } else {
          List<Map<String, dynamic>> suggestedUsers =
              scoreAndSortUsers(snapshot.data!, widget.userProfile);
          return ListView.builder(
            itemCount: suggestedUsers.length,
            itemBuilder: (context, index) {
              Map<String, dynamic> user = suggestedUsers[index];
              return SuggestedConnection(
                user: user,
                dismissedPressed: () async {
                  final String? fromId = FirebaseAuth.instance.currentUser?.uid;
                  final fromUserRef = FirebaseFirestore.instance
                      .collection('users')
                      .doc(fromId);
                  List<String> dismissed =
                      List<String>.from(widget.userProfile['dismissed'] ?? []);
                  if (!dismissed.contains(user["id"])) {
                    dismissed.add(user["id"]);
                    await fromUserRef.update({'dismissed': dismissed});
                    setState(() {
                      widget.userProfile['dismissed'] = dismissed;
                    });
                  }
                },
                connectPressed: () {
                  _showPopup(context, user);
                },
              );
            },
          );
        }
      },
    );
  }
}

class ConnectionRequestsPage extends StatefulWidget {
  final Map<String, dynamic> userProfile;
  final NotificationController notificationController;
  const ConnectionRequestsPage(
      {super.key,
      required this.userProfile,
      required this.notificationController});

  @override
  State<ConnectionRequestsPage> createState() => _ConnectionRequestsPageState();
}

class _ConnectionRequestsPageState extends State<ConnectionRequestsPage> {
  Timer? _timer;

  void _startTimer() {
    _timer = Timer(Duration(seconds: 10), _triggerEvent);
  }

  void _triggerEvent() {
    // Place your event code here
    widget.notificationController.removeNotification("connections");
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction == 1.0) {
      _startTimer();
    } else {
      _timer?.cancel();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: Key('connection-requests'),
      onVisibilityChanged: _onVisibilityChanged,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: getConnectionRequests(widget.userProfile),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else {
            List<Map<String, dynamic>> connectionRequests = snapshot.data!;
            return ListView.builder(
              itemCount: connectionRequests.length,
              itemBuilder: (context, index) {
                Map<String, dynamic> request = connectionRequests[index];
                return FutureBuilder(
                  future: FirebaseFirestore.instance
                      .collection("users")
                      .doc(request["from"])
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else {
                      final user = snapshot.data!;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: AvatarWidget(
                              userId: user.id,
                            ),
                            title: Text(user['fullname'],
                                style: Theme.of(context).textTheme.bodyLarge),
                            subtitle: Text(
                              "${Functions.calculateAge(user['dob'])} | ${user['gender']} | ${user['county']}, UK",
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: ExpandableText(user['bio'], maxLines: 4),
                          ),
                          Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Container(
                              width: double.infinity,
                              padding: EdgeInsets.all(8.0),
                              decoration: BoxDecoration(
                                color: Constants.toggleDefaultBgColor,
                                border: Border.all(
                                  color: Colors.grey[900]!,
                                  width: 1.0,
                                ),
                              ),
                              child: Text(request["post"]),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                TextButton(
                                    onPressed: () async {
                                      final String? fromId = FirebaseAuth
                                          .instance.currentUser?.uid;
                                      final fromUserRef = FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .doc(fromId);
                                      List<String> dismissed =
                                          List<String>.from(
                                              widget.userProfile['dismissed'] ??
                                                  []);
                                      if (!dismissed.contains(user.id)) {
                                        dismissed.add(user.id);
                                        await fromUserRef
                                            .update({'dismissed': dismissed});
                                        setState(() {
                                          widget.userProfile['dismissed'] =
                                              dismissed;
                                        });
                                      }
                                    },
                                    child: Text("Dismiss")),
                                TextButton(
                                    style: TextButton.styleFrom(
                                      backgroundColor: Colors.orange,
                                      foregroundColor: Colors.white,
                                      textStyle: TextStyle(fontSize: 16),
                                    ),
                                    onPressed: () async {
                                      //TODO remove incomming and outgoing ids
                                      final String? currentId = FirebaseAuth
                                          .instance.currentUser?.uid;
                                      final currentUserRef = FirebaseFirestore
                                          .instance
                                          .collection('users')
                                          .doc(currentId);
                                      List<String> friends = List<String>.from(
                                          widget.userProfile['friends'] ?? []);
                                      if (!friends.contains(user.id)) {
                                        friends.add(user.id);
                                        List<String> incoming =
                                            List<String>.from(widget
                                                    .userProfile['incoming'] ??
                                                []);
                                        if (incoming.contains(user.id)) {
                                          incoming.remove(user.id);
                                        }
                                        await currentUserRef.update({
                                          'friends': friends,
                                          'incoming': incoming
                                        });
                                        final fromUserRef = FirebaseFirestore
                                            .instance
                                            .collection('users')
                                            .doc(request["from"]);
                                        final fromUser =
                                            await fromUserRef.get();
                                        List<String> fromFriends =
                                            List<String>.from(fromUser
                                                    .data()!
                                                    .containsKey('friends')
                                                ? fromUser['friends']
                                                : []);
                                        if (!fromFriends.contains(currentId)) {
                                          fromFriends.add(currentId!);
                                          List<String> outgoing =
                                              List<String>.from(fromUser
                                                      .data()!
                                                      .containsKey('outgoing')
                                                  ? fromUser['outgoing']
                                                  : []);
                                          if (outgoing.contains(user.id)) {
                                            outgoing.remove(user.id);
                                          }
                                          await fromUserRef.update({
                                            'friends': friends,
                                            'outgoing': outgoing
                                          });
                                          Functions.showToast("Friend added.");
                                        }
                                        setState(() {
                                          widget.userProfile['friends'] =
                                              friends;
                                        });
                                      }
                                    },
                                    child: Text("Connect")),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                  },
                );
              },
            );
          }
        },
      ),
    );
  }
}
