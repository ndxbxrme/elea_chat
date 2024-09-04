import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSubmitted;
  final String userId;
  final String chatId;
  const ChatInput({
    super.key,
    required this.onSubmitted,
    required this.userId,
    required this.chatId,
  });
  @override
  _ChatInputState createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _controller = TextEditingController();
  FocusNode _focusNode = FocusNode();
  bool _showEmojiPicker = false;
  bool _isTyping = false;

  void _onEmojiSelected(Emoji emoji) {
    _controller
      ..text += emoji.emoji
      ..selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
  }

  void _toggleEmojiPicker() {
    setState(() {
      _showEmojiPicker = !_showEmojiPicker;
      if (_showEmojiPicker) {
        FocusScope.of(context).unfocus();
      } else {
        _focusNode.requestFocus();
      }
      _focusNode.addListener(() {
        if (_focusNode.hasFocus) {
        } else {
          _notifyUserStoppedTyping();
        }
      });
    });
  }

  void _notifyUserIsTyping() async {
    if (!_isTyping) {
      _isTyping = true;
      final docRef = _firestore
          .collection('typing')
          .doc('${widget.userId}_${widget.chatId}');

      // Check if the document already exists
      final docSnapshot = await docRef.get();

      if (!docSnapshot.exists) {
        // Only set the document if it doesn't already exist
        await docRef.set({
          'userId': widget.userId,
          'chatId': widget.chatId,
          'timestamp': Timestamp.now(),
        });
      }
    }
  }

  void _notifyUserStoppedTyping() {
    if (_isTyping) {
      _firestore
          .collection('typing')
          .doc('${widget.userId}_${widget.chatId}')
          .delete();
    }
    _isTyping = false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(_showEmojiPicker
                  ? Icons.keyboard
                  : Icons.emoji_emotions_outlined),
              onPressed: _toggleEmojiPicker,
            ),
            Expanded(
              child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: 'Message',
                    border: InputBorder.none,
                  ),
                  onChanged: (text) {
                    _notifyUserIsTyping();
                  },
                  onSubmitted: (value) {
                    widget.onSubmitted(value);
                    _controller.clear();
                    _notifyUserStoppedTyping();
                  }),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                // Implement send message functionality here
                widget.onSubmitted(_controller.text);
                _controller.clear();
                _notifyUserStoppedTyping();
              },
            ),
          ],
        ),
        Offstage(
          offstage: !_showEmojiPicker,
          child: SizedBox(
            height: 256,
            child: EmojiPicker(
              onEmojiSelected: (Category? category, Emoji emoji) {
                _onEmojiSelected(emoji);
              },
              config: Config(
                emojiViewConfig: EmojiViewConfig(),
                skinToneConfig: SkinToneConfig(),
                categoryViewConfig: CategoryViewConfig(),
                bottomActionBarConfig: BottomActionBarConfig(),
                searchViewConfig: SearchViewConfig(),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
