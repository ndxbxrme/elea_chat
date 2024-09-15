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

class ForYouScreen extends StatefulWidget {
  late String selectedTopic;
  final Map<String, dynamic> userProfile;
  final String? action;

  ForYouScreen({
    this.selectedTopic = 'All topics',
    required this.userProfile,
    this.action,
  });

  @override
  _ForYouScreenState createState() => _ForYouScreenState();
}

class _ForYouScreenState extends State<ForYouScreen> {
  late Future<List<String>> topicsFuture;
  late ScrollController _scrollController = ScrollController();
  Map<int, GlobalKey> _topicKeys = {};
  List<String> _topics = [];
  List<QueryDocumentSnapshot> _posts = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  final int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    topicsFuture = _fetchTopics();
    _loadPosts();
    if (widget.action != null && widget.action!.startsWith('forum')) {
      String postId = widget.action!.replaceFirst('forum_', '');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ForumPostScreen(
            postId: postId,
            userProfile: widget.userProfile,
          ),
        ),
      );
    }
  }

  void _initializeTopicKeys() {
    _topicKeys = {};
    for (var i = 0; i < _topics.length; i++) {
      _topicKeys[i] = GlobalKey();
    }
  }

  void _scrollToSelectedTopic() async {
    if (widget.selectedTopic != null) {
      int index = _topics.indexOf(widget.selectedTopic);
      if (index != -1) {
        final key = _topicKeys[index];
        final context = key!.currentContext;
        if (context != null) {
          await Scrollable.ensureVisible(context,
              duration: Duration(milliseconds: 500), curve: Curves.linear);
        }
      }
    }
  }

  Future<void> _loadPosts({bool isRefresh = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    if (isRefresh) {
      _lastDocument = null;
      _hasMore = true;
      _posts.clear();
    }

    int fetchedDocumentsCount = 0;

    while (fetchedDocumentsCount < _pageSize && _hasMore) {
      Query query = FirebaseFirestore.instance
          .collection('posts')
          .where('parentId', isEqualTo: '0')
          .orderBy('timestamp', descending: true)
          .limit(_pageSize - fetchedDocumentsCount);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      QuerySnapshot querySnapshot = await query.get();

      if (querySnapshot.docs.length < _pageSize - fetchedDocumentsCount) {
        _hasMore = false;
      }

      if (querySnapshot.docs.isNotEmpty) {
        _lastDocument = querySnapshot.docs.last;
      }

      List<QueryDocumentSnapshot> newPosts = querySnapshot.docs;

      // Get the list of blocked users
      List blockedUsers = widget.userProfile['blocked'] ?? [];

      // Filter out the blocked users
      List<QueryDocumentSnapshot> filteredDocs = newPosts.where((doc) {
        if (widget.selectedTopic != 'All topics') {
          return doc['topics'].contains(widget.selectedTopic) &&
              !blockedUsers.contains(doc['owner']);
        }
        return !blockedUsers.contains(doc['owner']);
      }).toList();

      setState(() {
        _posts.addAll(filteredDocs);
      });

      fetchedDocumentsCount += filteredDocs.length;

      if (querySnapshot.docs.isEmpty) {
        break; // Exit the loop if no more documents to fetch
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<List<String>> _fetchTopics() async {
    List<String> topics = [];
    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection("topics")
        .where("status", isEqualTo: "active")
        .get();
    for (var doc in snapshot.docs) {
      topics.add(doc['topic']);
    }
    topics.sort((a, b) => a.compareTo(b));
    widget.userProfile["topics"]
        .sort((a, b) => b.toString().compareTo(a.toString()));
    for (var userTopic in widget.userProfile["topics"]) {
      topics.insert(0, userTopic);
    }
    topics.insert(0, 'All topics');
    return topics;
  }

  Future<void> _refreshPosts() async {
    await _loadPosts(isRefresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EleaAppBar(
        title: 'For You',
        username: widget.userProfile["username"],
        userProfile: widget.userProfile,
        canMakeNewPost: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Container(
                height: 50.0,
                child: FutureBuilder<List<String>>(
                  future: topicsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    }
                    if (!snapshot.hasData) {
                      return SizedBox.shrink();
                    }
                    if (snapshot.data!.isEmpty) {
                      return Center(child: const Text("No topics found"));
                    }

                    _topics = snapshot.data!;
                    _initializeTopicKeys(); // Initialize keys after topics are fetched

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToSelectedTopic(); // Ensure scrolling to the selected topic after topics are set
                    });

                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      controller: _scrollController,
                      child: Row(
                        children: _topics.asMap().entries.map((entry) {
                          int index = entry.key;
                          String topic = entry.value;
                          return Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 3.0),
                            child: Container(
                              key: _topicKeys[index],
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.fromLTRB(
                                      16.0, 6.0, 16.0, 6.0),
                                  backgroundColor: topic == widget.selectedTopic
                                      ? Constants.toggleAllBgColor
                                      : Constants.toggleDefaultBgColor,
                                  foregroundColor: topic == widget.selectedTopic
                                      ? Colors.white
                                      : Constants.toggleAllBgColor,
                                  side: BorderSide(
                                    color: Constants
                                        .borderColor, // 1px grey border
                                    width: 1.0,
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    widget.selectedTopic = topic;
                                  });
                                  WidgetsBinding.instance
                                      .addPostFrameCallback((_) {
                                    _scrollToSelectedTopic();
                                  });
                                  _refreshPosts();
                                },
                                child: Text(topic),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                )),
          ),
          SizedBox(
            height: 20.0,
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: (ScrollNotification scrollInfo) {
                if (scrollInfo.metrics.pixels ==
                        scrollInfo.metrics.maxScrollExtent &&
                    !_isLoading) {
                  _loadPosts();
                }
                return false;
              },
              child: RefreshIndicator(
                onRefresh: _refreshPosts,
                child: ListView.builder(
                  itemCount: _posts.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == _posts.length) {
                      return SizedBox.shrink();
                    }

                    // Your post item widget here
                    DocumentSnapshot document = _posts[index];
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
                                                      ? "All topics"
                                                      : topic;
                                            });
                                            _refreshPosts();
                                          },
                                          child: Container(
                                              decoration: BoxDecoration(
                                                color: topic ==
                                                        widget.selectedTopic
                                                    ? Constants
                                                        .toggleSelectedBgColor
                                                    : Constants
                                                        .toggleDefaultBgColor,
                                                borderRadius:
                                                    BorderRadius.circular(25.0),
                                                border: Border.all(
                                                    color:
                                                        Constants.borderColor),
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.fromLTRB(
                                                        16.0, 6.0, 16.0, 6.0),
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
                                    onTap: () async {
                                      final userRef = FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(document["owner"]);
                                      Map<String, dynamic>? user =
                                          (await userRef.get()).data();
                                      Functions.showConnectionRequestPopup(
                                          context, user!);
                                    },
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
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
