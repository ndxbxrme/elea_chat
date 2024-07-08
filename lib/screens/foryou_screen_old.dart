import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elea_chat/components/elea_app_bar.dart';
import 'package:elea_chat/screens/forum_post_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/avatar_widget.dart';
import '../components/expandable_text.dart';
import '../constants.dart';
import '../functions.dart';
import 'profile_screen.dart';

// ignore: must_be_immutable
class ForYouScreen extends StatefulWidget {
  late String? selectedTopic;
  final Map<String, dynamic> userProfile;
  ForYouScreen(
      {super.key,
      this.selectedTopic = 'All topics',
      required this.userProfile});

  @override
  State<ForYouScreen> createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  late Future<List<String>> topicsFuture;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    topicsFuture = fetchTopics();
    _scrollController = ScrollController();
  }

  Future<List<String>> fetchTopics() async {
    List<String> topics = [];
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("topics")
        .where("status", isEqualTo: "active")
        .get();
    for (var doc in snapshot.docs) {
      topics.add(doc['topic']);
    }
    topics.insert(0, 'All topics');
    return topics;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EleaAppBar(
        title: 'For You',
        username: widget.userProfile["username"],
      ),
      body: Column(
        children: [
          Container(
            height: 50.0,
            child: FutureBuilder(
              future: topicsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                }
                if (!snapshot.hasData) {
                  return Center(child: const Text("Loading..."));
                }
                if (snapshot.data!.isEmpty) {
                  return Center(child: const Text("No topics found"));
                }
                List<String> topics = snapshot.data!;
                return ListView.builder(
                  scrollDirection: Axis.horizontal,
                  controller: _scrollController,
                  itemCount: topics.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0,
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor:
                                topics[index] == widget.selectedTopic
                                    ? Constants.toggleSelectedBgColor
                                    : Constants.toggleDefaultBgColor),
                        onPressed: () {
                          setState(() {
                            widget.selectedTopic = topics[index];
                          });
                        },
                        child: Text(topics[index]),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          SizedBox(
            height: 20.0,
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.selectedTopic == 'All topics'
                  ? FirebaseFirestore.instance
                      .collection('posts')
                      .where('parentId', isEqualTo: '0')
                      .snapshots()
                  : FirebaseFirestore.instance
                      .collection('posts')
                      .where('parentId', isEqualTo: '0')
                      .where('topics', arrayContains: widget.selectedTopic)
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                if (!snapshot.hasData) {
                  return const Text("Loading...");
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Text("No posts here");
                }
                // Get the list of blocked users
                List blockedUsers = widget.userProfile['blocked'] ?? [];
                // Filter out the blocked users
                List<QueryDocumentSnapshot> filteredDocs =
                    snapshot.data!.docs.where((doc) {
                  return !blockedUsers.contains(doc['owner']);
                }).toList();
                if (filteredDocs.isEmpty) {
                  return const Text("No posts here");
                }
                // Sort the remaining posts by timestamp
                filteredDocs.sort((a, b) => (b['timestamp'] as Timestamp)
                    .compareTo(a['timestamp'] as Timestamp));
                return ListView.builder(
                  padding: EdgeInsets.only(bottom: 100.0),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot document = filteredDocs[index];
                    return Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForumPostScreen(
                                    postId: document.id,
                                    userProfile: widget.userProfile,
                                  ),
                                ),
                              );
                            },
                            child: ListTile(
                              leading: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfileScreen(
                                        userId: document["owner"],
                                      ),
                                    ),
                                  );
                                },
                                child: AvatarWidget(
                                  userId: document["owner"],
                                ),
                              ),
                              trailing: PopupMenuButton<String>(
                                padding:
                                    EdgeInsets.fromLTRB(0.6, 0.6, 0.0, 0.6),
                                onSelected: (String result) async {
                                  switch (result) {
                                    case 'Block User':
                                      setState(() {
                                        widget.userProfile["blocked"] =
                                            widget.userProfile['blocked'] ?? [];
                                        widget.userProfile["blocked"]
                                            .add(document["owner"]);
                                      });
                                      final userId = FirebaseAuth
                                          .instance.currentUser!.uid;
                                      final userRef = FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(userId);
                                      await userRef.update({
                                        "blocked": widget.userProfile["blocked"]
                                      });
                                      Functions.showToast("User blocked.");
                                      break;
                                    default:
                                  }
                                },
                                itemBuilder: (BuildContext context) =>
                                    <PopupMenuEntry<String>>[
                                  if (widget.userProfile["id"] !=
                                      document["owner"])
                                    PopupMenuItem<String>(
                                      value: 'Block User',
                                      child: Text(
                                        'Block User',
                                      ),
                                    ),
                                  PopupMenuItem<String>(
                                    value: 'Option 2',
                                    child: Text(
                                      'Option 2',
                                    ),
                                  )
                                ],
                                icon: Icon(Icons.more_horiz),
                              ),
                              title: Text(
                                document["title"],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              subtitle: Text(
                                document["username"] +
                                    " | " +
                                    Functions.formatDate(document["timestamp"]),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ForumPostScreen(
                                    postId: document.id,
                                    userProfile: widget.userProfile,
                                  ),
                                ),
                              );
                            },
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16.0),
                              /*child: Text(
                                document["post"],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: TextStyle(fontSize: 14.0),
                              ),*/
                              child: ExpandableText(
                                document["post"],
                                maxLines: 2,
                              ),
                            ),
                          ),
                          SizedBox(height: 16.0),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Wrap(
                                runSpacing: 6.0,
                                spacing: 6.0,
                                alignment: WrapAlignment.start,
                                crossAxisAlignment: WrapCrossAlignment.start,
                                children: document["topics"]
                                    .map<Widget>((topic) => GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              widget.selectedTopic =
                                                  widget.selectedTopic == topic
                                                      ? null
                                                      : topic;
                                            });
                                          },
                                          child: Container(
                                              decoration: BoxDecoration(
                                                color: Constants
                                                    .toggleDefaultBgColor,
                                                borderRadius:
                                                    BorderRadius.circular(25.0),
                                                border: Border.all(
                                                    color: Colors.grey),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 6.0),
                                                child: Text(topic),
                                              )),
                                        ))
                                    .toList()),
                          ),
                          SizedBox(height: 16.0),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    print("hello");
                                  },
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.comment_outlined,
                                      ),
                                      SizedBox(width: 6.0),
                                      Text(
                                        document["numSubposts"].toString(),
                                      ),
                                    ],
                                  ),
                                ),
                                Row(children: [
                                  GestureDetector(
                                    child: Icon(Icons.share_outlined),
                                  ),
                                  SizedBox(width: 6.0),
                                  GestureDetector(
                                    child: Icon(Icons.reply_outlined),
                                  ),
                                ]),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Container(
                              height: 1,
                              color: Colors.grey[300],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
