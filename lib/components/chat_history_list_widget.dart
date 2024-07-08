import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'chat_message_widget.dart';
import 'chat_date_widget.dart';

class ChatHistoryListWidget extends StatefulWidget {
  final String chatId;
  const ChatHistoryListWidget({super.key, required this.chatId});

  @override
  State<ChatHistoryListWidget> createState() => _ChatHistoryListWidgetState();
}

class _ChatHistoryListWidgetState extends State<ChatHistoryListWidget> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _listViewKey = GlobalKey();
  bool _isScrolledUp = false;
  bool _isLoadingMore = false;
  bool _hasMoreMessages = true;
  List<DocumentSnapshot> _messages = [];
  DocumentSnapshot? _lastDocument;
  final int _pageSize = 5;
  double _scrollThreshold = 0.0;

  @override
  void initState() {
    super.initState();
    /*WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateScrollThreshold();
    });
    _scrollController.addListener(_scrollListener);
    _loadInitialMessages();*/
  }

  void _scrollListener() {
    if (_scrollController.position.pixels > _scrollThreshold &&
        !_isLoadingMore &&
        _hasMoreMessages) {
      _loadMoreMessages();
    }

    /*setState(() {
      _isScrolledUp = _scrollController.position.userScrollDirection ==
          ScrollDirection.forward;
    });*/
  }

  void _updateScrollThreshold() {
    if (_listViewKey.currentContext != null) {
      double listViewHeight = _listViewKey.currentContext!.size!.height;
      const double scrollFraction = 0.2; // Adjust this fraction as needed
      setState(() {
        _scrollThreshold = listViewHeight * scrollFraction;
      });
    }
  }

  Future<void> _loadInitialMessages() async {
    Query query = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(_pageSize);

    QuerySnapshot querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      _lastDocument = querySnapshot.docs.last;
    }

    print('Initial docs length ${querySnapshot.docs.length}');
    for (var doc in querySnapshot.docs) {
      print('Initial message timestamp: ${doc['timestamp']}');
      print('Initial message text: ${doc['text']}');
    }

    setState(() {
      _messages = querySnapshot.docs;
      _hasMoreMessages = querySnapshot.docs.length == _pageSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateScrollThreshold();
      });
    });
  }

  Future<void> _loadMoreMessages() async {
    print('load more messages');
    if (_lastDocument == null) return;

    setState(() {
      _isLoadingMore = true;
    });

    Query query = FirebaseFirestore.instance
        .collection('chats')
        .doc(widget.chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .startAfterDocument(_lastDocument!)
        .limit(_pageSize);

    QuerySnapshot querySnapshot = await query.get();

    if (querySnapshot.docs.isNotEmpty) {
      _lastDocument = querySnapshot.docs.last;
    } else {
      _lastDocument = null; // No more messages to load
    }

    print('More docs length ${querySnapshot.docs.length}');
    for (var doc in querySnapshot.docs) {
      print('More message timestamp: ${doc['timestamp']}');
    }

    setState(() {
      final newMessages = querySnapshot.docs.where((newDoc) {
        return !_messages.any((existingDoc) => existingDoc.id == newDoc.id);
      }).toList();
      _messages.addAll(newMessages);
      _isLoadingMore = false;
      _hasMoreMessages = querySnapshot.docs.length == _pageSize;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateScrollThreshold();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('chats')
              .doc(widget.chatId)
              .collection('messages')
              .orderBy('timestamp', descending: true)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              print('snapshot has data');
              // Add new messages to the beginning of the list
              final newMessages = snapshot.data!.docs;
              _messages.insertAll(
                  0,
                  newMessages.where(
                      (doc) => !_messages.any((msg) => msg.id == doc.id)));

              return ListView.separated(
                key: _listViewKey,
                controller: _scrollController,
                reverse: true,
                separatorBuilder: (context, index) {
                  //return SizedBox.shrink();
                  if (index == 0) {
                    return const SizedBox.shrink();
                  }
                  if (index >= _messages.length) {
                    return const SizedBox.shrink();
                  }
                  final message = _messages[index - 1];
                  final previousMessage = _messages[index];
                  final difference = message
                      .get('timestamp')
                      .toDate()
                      .difference(previousMessage.get('timestamp').toDate());

                  if (difference.inHours >= 1) {
                    return ChatDateWidget(
                      date: message.get('timestamp').toDate(),
                    );
                  }

                  return const SizedBox.shrink();
                },
                itemCount: _messages.length + (_isLoadingMore ? 1 : 0) + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _isScrolledUp
                        ? IconButton(
                            icon: const Icon(Icons.arrow_downward),
                            onPressed: () {
                              _scrollController.animateTo(
                                _scrollController.position.maxScrollExtent,
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                          )
                        : const SizedBox.shrink();
                  }

                  if (index == _messages.length + 1) {
                    return _isLoadingMore
                        ? const Center(child: CircularProgressIndicator())
                        : const SizedBox.shrink();
                  }

                  final message = _messages[index - 1];
                  return ChatMessageWidget(
                    messageText: message['text'],
                    messageTimestamp: message['timestamp'],
                    messageUserId: message['userId'],
                    messageId: message.id,
                    image: message['image'],
                    currentUserId: FirebaseAuth.instance.currentUser!.uid,
                    onReply: (messageId) {
                      print(messageId);
                    },
                    onEdit: (messageId) {
                      print(messageId);
                    },
                    onDelete: (messageId) {
                      print(messageId);
                    },
                  );
                },
              );
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
