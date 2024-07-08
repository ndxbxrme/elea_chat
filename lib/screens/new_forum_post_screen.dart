import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

import '../components/elea_text_box.dart';
import '../constants.dart';

class NewForumPostScreen extends StatefulWidget {
  final String username;

  NewForumPostScreen({required this.username});

  @override
  _NewForumPostScreenState createState() => _NewForumPostScreenState();
}

class _NewForumPostScreenState extends State<NewForumPostScreen> {
  TextEditingController _controller = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  // Selected topics
  List<String> _selectedTopics = [];
  String? postTitle = "";

  String? validateText(String value) {
    if (value.isEmpty) {
      return 'Text cannot be empty';
    }
    return null;
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
    return topics;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: FutureBuilder(
          future: fetchTopics(),
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
            List<String> _topics = snapshot.data!;
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.all(0.0),
                      title: Center(child: Text("New Post")),
                      leading: SizedBox(width: 24.0),
                      trailing: IconButton(
                        icon: Icon(Icons.close),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                    const SizedBox(height: 20.0),
                    EleaTextBox(
                      labelText: "Post Title",
                      initialValue: "",
                      // ignore: avoid_print
                      onSaved: (newValue) {
                        postTitle = newValue;
                      },
                    ),
                    const SizedBox(height: 20.0),
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
                    MultiSelectDialogField(
                      items: _topics
                          .map((topic) => MultiSelectItem<String>(topic, topic))
                          .toList(),
                      title: Text("Select Topics"),
                      selectedColor: Colors.blue,
                      buttonText: Text(
                        "Select Topics",
                        style: TextStyle(color: Colors.black, fontSize: 16),
                      ),
                      onConfirm: (results) {
                        _selectedTopics = results.cast<String>();
                      },
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
                          try {
                            await FirebaseFirestore.instance
                                .collection('posts')
                                .add({
                              'parentId': '0',
                              'timestamp': Timestamp.now(),
                              'likes': 0,
                              'numSubposts': 0,
                              'status': 'active',
                              'images': [],
                              'owner': FirebaseAuth.instance.currentUser?.uid,
                              'title': postTitle,
                              'post': _controller.text,
                              'topics': _selectedTopics,
                              'username': widget.username
                            });
                          } catch (error) {}
                          Navigator.of(context).pop(); // Close the dialog
                        }
                      },
                      child: Text('Submit'),
                    ),
                  ],
                ),
              ),
            );
          }),
    );
  }
}
