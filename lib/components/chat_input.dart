import 'package:flutter/material.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSubmitted;

  const ChatInput({super.key, required this.onSubmitted});
  @override
  _ChatInputState createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  TextEditingController _controller = TextEditingController();
  FocusNode _focusNode = FocusNode();
  bool _showEmojiPicker = false;

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
    });
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
                  onSubmitted: (value) {
                    widget.onSubmitted(value);
                    _controller.clear();
                  }),
            ),
            IconButton(
              icon: Icon(Icons.send),
              onPressed: () {
                // Implement send message functionality here
                widget.onSubmitted(_controller.text);
                _controller.clear();
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
