import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elea_chat/components/chat_history_list_widget.dart';
import 'package:elea_chat/components/typing_indicator_widget.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../components/avatar_widget.dart';
import '../components/chat_input.dart';
import '../components/notification_controller.dart';
import '../functions.dart';

Future<Map<String, dynamic>> fetchData(String chatId) async {
  final chat =
      await FirebaseFirestore.instance.collection('chats').doc(chatId).get();
  final chatData = chat.data();
  final currentId = FirebaseAuth.instance.currentUser?.uid;
  final friendId =
      Functions.firstNonMatchingItem(chatData!['participants'], currentId!);
  final friend =
      await FirebaseFirestore.instance.collection('users').doc(friendId).get();
  final friendData = friend.data();
  return {
    'chat': chatData,
    'friend': friendData,
    'friendId': friendId,
    'currentId': currentId
  };
}

class ChatMessagesScreen extends StatefulWidget {
  final String chatId;
  final Function(String) setCurrentScreen;
  ChatMessagesScreen(
      {super.key, required this.chatId, required this.setCurrentScreen});
  @override
  State<ChatMessagesScreen> createState() => _ChatMessagesScreenState();
}

class _ChatMessagesScreenState extends State<ChatMessagesScreen> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    widget.setCurrentScreen("chats_${widget.chatId}");
  }

  @override
  void dispose() {
    // TODO: implement dispose
    widget.setCurrentScreen("");
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: fetchData(widget.chatId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData) {
          return Center(child: Text('No data found'));
        } else {
          final data = snapshot.data!;
          final chat = data['chat'];
          final friend = data['friend'];
          final currentId = data['currentId'];
          final friendId = data['friendId'];
          return Scaffold(
            appBar: AppBar(
                title: Center(
                  child: Text(
                    friend["fullname"],
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                    ),
                    child: AvatarWidget(
                      userId: friendId,
                    ),
                  ),
                ]),
            body: Container(
              child: Column(
                children: [
                  Expanded(
                    child: ChatHistoryListWidget(
                      chatId: widget.chatId,
                      friendId: friendId,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(25),
                              border: Border.all(
                                color: Colors.grey[600]!,
                                width: 1.0,
                              ),
                            ),
                            child: ChatInput(
                              onSubmitted: (value) async {
                                final text = value.trim();
                                if (text.isNotEmpty) {
                                  await FirebaseFirestore.instance
                                      .collection('chats')
                                      .doc(widget.chatId)
                                      .collection('messages')
                                      .add({
                                    'text': text,
                                    'image': null,
                                    'userId': currentId,
                                    'timestamp': Timestamp.now(),
                                  });
                                  final chatRef = FirebaseFirestore.instance
                                      .collection('chats')
                                      .doc(widget.chatId);
                                  await chatRef.update({
                                    'last': {
                                      'image': null,
                                      'text': text,
                                      'userId': currentId,
                                      'timestamp': Timestamp.now(),
                                    }
                                  });
                                  final docRef = FirebaseFirestore.instance
                                      .collection('notifications')
                                      .doc('${friendId}_${widget.chatId}');

                                  // Check if the document already exists
                                  final docSnapshot = await docRef.get();

                                  if (!docSnapshot.exists) {
                                    // Only set the document if it doesn't already exist
                                    await docRef.set({
                                      'userId': friendId,
                                      'screen': 'chats_${widget.chatId}',
                                      'timestamp': Timestamp.now(),
                                    });
                                  }
                                }
                              },
                              userId: currentId,
                              chatId: widget.chatId,
                            ),
                            /*child: TextField(
                              controller: _textController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                              ),
                            ),*/
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }
}
