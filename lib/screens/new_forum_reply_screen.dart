import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class NewForumReplyScreen extends StatefulWidget {
  final String username;
  final String postId;

  NewForumReplyScreen({required this.username, required this.postId});

  @override
  _NewForumReplyScreenState createState() => _NewForumReplyScreenState();
}

class _NewForumReplyScreenState extends State<NewForumReplyScreen> {
  final TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  String? validateText(String value) {
    if (value.isEmpty) {
      return 'Text cannot be empty';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.all(0.0),
                title: Center(child: Text("Reply to Post")),
                leading: SizedBox(width: 24.0),
                trailing: IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ),
              Container(
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
                    controller: _controller,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Enter your forum post here...',
                      contentPadding: EdgeInsets.all(10.0),
                    ),
                    maxLines: null, // Allows for multiline input
                    textInputAction: TextInputAction.newline,
                    validator: (value) => validateText(value!),
                  ),
                ),
              ),
              SizedBox(height: 20.0),
              TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  textStyle: TextStyle(fontSize: 20),
                ),
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    _formKey.currentState!.save();
                    final String? currentId =
                        FirebaseAuth.instance.currentUser?.uid;
                    try {
                      await firestore.collection('posts').add({
                        'parentId': widget.postId,
                        'timestamp': Timestamp.now(),
                        'likes': 0,
                        'numSubposts': 0,
                        'status': 'active',
                        'images': [],
                        'owner': currentId,
                        'title': "",
                        'post': _controller.text,
                        'username': widget.username
                      });
                      // Reference to the user document
                      DocumentReference userRef =
                          firestore.collection('users').doc(currentId);

                      // Update the numReplies field with an increment of 1
                      userRef.update({"numReplies": FieldValue.increment(1)});

                      // Reference to the post document
                      DocumentReference postRef =
                          firestore.collection('posts').doc(widget.postId);

                      // Update the numSubposts field with an increment of 1
                      postRef.update({"numSubposts": FieldValue.increment(1)});
                    } catch (error) {}
                    Navigator.of(context).pop(); // Close the dialog
                  }
                },
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
