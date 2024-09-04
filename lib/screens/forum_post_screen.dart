import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../components/avatar_widget.dart';
import '../components/elea_app_bar.dart';
import '../components/expandable_text.dart';
import '../constants.dart';
import '../functions.dart';
import 'new_forum_reply_screen.dart';

Future<Map<String, dynamic>?> fetchPostDetails(String postId) async {
  final postSnapshot =
      await FirebaseFirestore.instance.collection('posts').doc(postId).get();
  if (!postSnapshot.exists) {
    return {};
  }
  final post = postSnapshot.data();
  return post;
}

class ForumPostScreen extends StatelessWidget {
  final String postId;
  final Map<String, dynamic> userProfile;
  const ForumPostScreen({
    super.key,
    required this.postId,
    required this.userProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: EleaAppBar(
        title: 'For You',
        username: userProfile["username"],
        userProfile: userProfile,
        canMakeNewPost: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder(
              future: fetchPostDetails(postId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }
                final document = snapshot.data;
                if (document == null) {
                  return const CircularProgressIndicator();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ListTile(
                      leading: AvatarWidget(
                        userId: document["owner"],
                      ),
                      trailing: IconButton(
                          onPressed: () {}, icon: Icon(Icons.more_horiz)),
                      title: Text(document["title"],
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                          style: Theme.of(context).textTheme.bodyLarge),
                      subtitle: Text(
                        document["username"] +
                            " | " +
                            Functions.formatDate(document["timestamp"]),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Text(
                        document["post"],
                        style: TextStyle(fontSize: 14.0),
                      ),
                    ),
                    SizedBox(height: 6.0),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Wrap(
                        runSpacing: 6.0,
                        spacing: 6.0,
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: document["topics"]
                            .map<Widget>(
                              (topic) => Container(
                                decoration: BoxDecoration(
                                  color: Constants.toggleDefaultBgColor,
                                  borderRadius: BorderRadius.circular(25.0),
                                  border: Border.all(color: Colors.grey),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6.0),
                                  child: Text(topic),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                    SizedBox(height: 16.0),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              showDialog(
                                context: context,
                                barrierDismissible: true,
                                builder: (BuildContext context) {
                                  return Dialog(
                                    child: NewForumReplyScreen(
                                      username: userProfile['username'],
                                      postId: postId,
                                    ),
                                  );
                                },
                              );
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
                        height: 3,
                        color: Colors.grey[300],
                      ),
                    ),
                  ],
                );
              },
            ),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .where('parentId', isEqualTo: postId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text("Error: ${snapshot.error}");
                }
                if (!snapshot.hasData) {
                  return const Text("Loading...");
                }
                if (snapshot.data!.docs.isEmpty) {
                  return const Text("No replies yet");
                }
                List<QueryDocumentSnapshot> sortedDocs = snapshot.data!.docs;
                sortedDocs.sort((a, b) => (a['timestamp'] as Timestamp)
                    .compareTo(b['timestamp'] as Timestamp));
                return ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: sortedDocs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot document = sortedDocs[index];
                    return Container(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: AvatarWidget(
                              userId: document["owner"],
                            ),
                            trailing: IconButton(
                                onPressed: () {
                                  Functions.showToast("Nothing to see here");
                                },
                                icon: Icon(Icons.more_horiz)),
                            title: Text(document["username"],
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                                style: Theme.of(context).textTheme.bodyLarge),
                            subtitle: Text(
                              document["username"] +
                                  " | " +
                                  Functions.formatDate(document["timestamp"]),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: ExpandableText(
                              document["post"],
                              maxLines: 20,
                            ),
                          ),
                          SizedBox(height: 6.0),
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
            SizedBox(height: 100.0),
          ],
        ),
      ),
    );
  }
}
