import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elea_chat/components/avatar_upload_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/avatar_widget.dart';
import '../components/elea_app_bar.dart';
import '../constants.dart';
import '../functions.dart';
import 'topics_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic>? myProfile;
  const ProfileScreen({
    super.key,
    required this.userId,
    this.myProfile,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(widget.userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text("Error: ${snapshot.error}"));
        }
        if (!snapshot.hasData) {
          return Center(child: const Text("Loading..."));
        }
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return Center(child: Text("User not found"));
        }

        // Safely get the data from the snapshot
        final Map<String, dynamic> userProfile =
            snapshot.data!.data() as Map<String, dynamic>;
        userProfile["id"] = widget.userId;
        final Random random = Random();
        userProfile["rnd"] = random.nextInt(999999);
        final bool isOwner =
            widget.userId == FirebaseAuth.instance.currentUser?.uid;
        return Scaffold(
          appBar: EleaAppBar(
            title: userProfile["fullname"],
            userProfile: userProfile,
          ),
          body: GestureDetector(
            onTap: () {
              FocusScope.of(context).unfocus();
            },
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Center(
                    child: isOwner
                        ? AvatarUploadWidget(
                            avatarUrl:
                                "https://firebasestorage.googleapis.com/v0/b/elea-c.appspot.com/o/avatars%2F${userProfile["id"]}.jpg?alt=media&token=80fe8000-73f5-4273-b6bb-85615fa168cf&rnd=${userProfile["rnd"]}",
                            onAvatarChanged: (value) async {
                              userProfile["avatarUrl"] = value;
                              try {
                                await FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(userProfile["id"])
                                    .update({
                                  "avatarUrl": userProfile["avatarUrl"],
                                });
                                userProfile["rnd"] = random.nextInt(999999);

                                widget.myProfile?["rnd"] = userProfile["rnd"];

                                await FirebaseFirestore.instance
                                    .collection('notifications')
                                    .add({
                                  'userId': userProfile["id"],
                                  'screen': 'avatar',
                                  'timestamp': Timestamp.now(),
                                });
                              } catch (e) {
                                print("bad error $e");
                              }
                            },
                          )
                        : AvatarWidget(userId: widget.userId, radius: 100.0),
                  ),
                  Center(
                    child: Text(userProfile["username"]),
                  ),
                  Text(
                    "${Functions.calculateAge(userProfile['dob'])} | ${userProfile['gender']} | ${userProfile['county']}, UK",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  SizedBox(height: 20.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => TopicsScreen(
                              selectedTopics: userProfile['topics'],
                            ),
                          ),
                        );
                      },
                      child: Wrap(
                        runSpacing: 6.0,
                        spacing: 6.0,
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.start,
                        children: userProfile["topics"]
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
                  ),
                  const SizedBox(height: 20.0),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: Colors.grey[600]!,
                          width: 1.0,
                        ),
                      ),
                      padding: const EdgeInsets.all(8.0),
                      height: 200.0, // Fixed height for the text input area
                      child: SingleChildScrollView(
                        child: TextFormField(
                            initialValue: userProfile["bio"],
                            enabled: isOwner,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter your bio here...',
                              contentPadding: EdgeInsets.all(10.0),
                            ),
                            maxLines: null, // Allows for multiline input
                            textInputAction: TextInputAction.newline,
                            onChanged: (value) async {
                              userProfile["bio"] = value;
                              try {
                                await FirebaseFirestore.instance
                                    .collection("users")
                                    .doc(userProfile["id"])
                                    .update({
                                  "bio": userProfile["bio"],
                                });
                              } catch (e) {}
                            }),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
