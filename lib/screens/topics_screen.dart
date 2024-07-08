import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elea_chat/constants.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../components/custom_topics_form_field.dart';
import '../components/elea_app_bar.dart';

class TopicsScreen extends StatelessWidget {
  final List<dynamic> selectedTopics;
  TopicsScreen({
    super.key,
    required this.selectedTopics,
  });

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
    final List<String> stringList = selectedTopics.cast<String>();
    final Set<String> _selectedTopics = stringList.toSet();
    return Scaffold(
      appBar: EleaAppBar(
        title: "Topics",
      ),
      body: Column(
        children: [
          Padding(
            padding: Constants.horizontalPadding,
            child: Center(
              child: Text(
                  'Tell us which topics you would like to discuss with others.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
          ),
          Padding(
            padding: Constants.horizontalPadding,
            child: Center(
              child: Text('You can select as many topics as you like.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall),
            ),
          ),
          const SizedBox(height: 20.0),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: Constants.horizontalPadding,
                    child: FutureBuilder(
                      future: fetchTopics(),
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return Center(
                              child: Text("Error: ${snapshot.error}"));
                        }
                        if (!snapshot.hasData) {
                          return Center(child: const Text("Loading..."));
                        }
                        if (snapshot.data!.isEmpty) {
                          return Center(child: const Text("No topics found"));
                        }
                        List<String> topics = snapshot.data!;
                        return CustomTopicsFormField(
                          topics: topics,
                          selectedTopics: _selectedTopics,
                          onChanged: (selected) {
                            selectedTopics.clear();
                            selectedTopics.addAll(selected);
                            try {
                              final userId =
                                  FirebaseAuth.instance.currentUser!.uid;
                              DocumentReference userRef = FirebaseFirestore
                                  .instance
                                  .collection('users')
                                  .doc(userId);
                              userRef
                                  .update({"topics": selectedTopics.toList()});
                            } catch (e) {}
                          },
                          validator: (selected) {
                            if (selected!.isEmpty) {
                              return 'Please select at least one topic';
                            }
                            return null;
                          },
                          onSaved: (Set<String>? newValue) {
                            //data.topics = newValue;
                          },
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 60.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
