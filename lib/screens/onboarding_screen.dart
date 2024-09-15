import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elea_chat/components/elea_county_picker.dart';
import 'package:elea_chat/components/elea_gender_selector.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../components/custom_topics_form_field.dart';
import '../components/elea_text_box.dart';
import '../components/elea_date_picker.dart';
import '../components/elea_county_picker.dart';
import '../components/terms_conditions_widget.dart';
import '../components/username_text_box.dart';
import 'signup_screen.dart';
import 'main_app_screen.dart';
import '../constants.dart';
import '../app_router.dart';

class OnboardingData {
  String username;
  String email;
  String gender;
  String fullname;
  String dob;
  String county;
  bool acceptedTOS;
  Set<String>? topics;
  OnboardingData({
    this.username = '',
    this.email = '',
    this.gender = '',
    this.fullname = '',
    this.dob = '',
    this.county = '',
    this.acceptedTOS = false,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _OnboardingScreenState createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final List<bool> _completedPages = [true, false, false];
  final GlobalKey<FormState> _formKey1 = GlobalKey<FormState>();
  final GlobalKey<FormState> _formKey2 = GlobalKey<FormState>();
  int _currentPage = 0;
  final OnboardingData _data = OnboardingData();
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  bool _validateAndSave() {
    GlobalKey<FormState> currentFormKey;
    if (_currentPage == 0) {
      currentFormKey = _formKey1;
    } else {
      currentFormKey = _formKey2;
    }
    if (currentFormKey.currentState!.validate()) {
      currentFormKey.currentState!.save();
      return true;
    }
    return false;
  }

  void _markPageAsCompleted(int pageIndex) {
    setState(() {
      _completedPages[pageIndex] = true;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child:
              Text('elea', style: Theme.of(context).textTheme.headlineMedium),
        ),
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: PageView(
          controller: _pageController,
          //physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (int page) {
            if (page > _currentPage) {
              // Prevent forward navigation to incomplete pages
              if (!_completedPages[page]) {
                _pageController.jumpToPage(_currentPage);
              } else {
                setState(() {
                  _currentPage = page;
                });
              }
            } else {
              setState(() {
                _currentPage = page;
              });
            }
          },
          children: [
            OnboardingPage1(data: _data, formKey: _formKey1),
            OnboardingPage2(data: _data, formKey: _formKey2),
          ],
        ),
      ),
      bottomSheet: Container(
        width: double.infinity,
        decoration: BoxDecoration(color: Colors.white),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 8.0, horizontal: 20.0),
              child: _currentPage == 1
                  ? TextButton(
                      onPressed: () async {
                        // Submit the info
                        if (_validateAndSave()) {
                          try {
                            await _firestore
                                .collection('users')
                                .doc(FirebaseAuth.instance.currentUser?.uid)
                                .set(
                              {
                                'username': _data.username,
                                'fullname': _data.fullname,
                                'dob': _data.dob,
                                'gender': _data.gender,
                                'county': _data.county,
                                'topics': _data.topics?.toList(),
                                'timestamp': Timestamp.now(),
                              },
                              SetOptions(merge: true),
                            );
                          } catch (error) {}
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setBool(
                                '${user.uid}-onboardingComplete', true);
                          }
                          router.push('/main/main');
                          //router.pushNamed('/main/main');
                          /*Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MainAppScreen()),
                          );*/
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Constants.orangeColor,
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(fontSize: 20),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 20.0),
                        child: const Text("Done"),
                      ),
                    )
                  : TextButton(
                      onPressed: () {
                        // Submit the info
                        if (_validateAndSave()) {
                          _markPageAsCompleted(_currentPage + 1);
                          _data.acceptedTOS = true;
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.ease,
                          );
                        }
                      },
                      style: TextButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        textStyle: TextStyle(fontSize: 20),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(
                            vertical: 8.0, horizontal: 20.0),
                        child: Text("Get Started"),
                      ),
                    ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage1 extends StatelessWidget {
  final OnboardingData data;
  final GlobalKey<FormState> formKey;
  const OnboardingPage1({
    super.key,
    required this.data,
    required this.formKey,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Form(
        key: formKey,
        child: Column(
          children: [
            const Padding(
              padding: Constants.horizontalPadding,
              child: Center(
                child: Text(
                  'Give us some quick info about yourself so we can tailor an experience personally to you.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const SizedBox(height: 20.0),
            Padding(
              padding: Constants.horizontalPadding,
              child: EleaTextBox(
                labelText: "Full Name*",
                initialValue: data.fullname,
                onValidate: (newValue) {
                  if (newValue == null || newValue.isEmpty) {
                    return "Please enter your full name.";
                  }
                  return null;
                },
                onSaved: (newValue) {
                  data.fullname = newValue ?? "";
                },
              ),
            ),
            const SizedBox(height: 20.0),
            Padding(
              padding: Constants.horizontalPadding,
              child: UsernameTextBox(
                labelText: "User Name*",
                initialValue: data.username,
                onSaved: (newValue) {
                  data.username = newValue ?? "";
                },
              ),
            ),
            const SizedBox(height: 20.0),
            Padding(
              padding: Constants.horizontalPadding,
              child: DatePickerField(
                labelText: "Date of Birth*",
                labelSubtext:
                    "(so we can connect you with similar aged people)",
                initialValue: data.dob,
                // ignore: avoid_print
                onSaved: (newValue) {
                  data.dob = newValue ?? "";
                },
              ),
            ),
            const SizedBox(height: 20.0),
            Padding(
              padding: Constants.horizontalPadding,
              child: EleaGenderSelector(
                  labelText: "Gender*",
                  initialValue: data.gender,
                  onSaved: (newValue) {
                    data.gender = newValue ?? "Other";
                  }),
            ),
            const SizedBox(height: 20.0),
            Padding(
              padding: Constants.horizontalPadding,
              child: EleaCountyPicker(
                labelText: "County (optional)",
                initialValue: data.county,
                // ignore: avoid_print
                onChanged: (newValue) {
                  data.county = newValue ?? "";
                },
              ),
            ),
            const SizedBox(height: 20.0),
            Padding(
              padding: Constants.horizontalPadding,
              child: TermsConditionsWidget(
                formKey: formKey,
                initialValue: data.acceptedTOS,
                onSubmit: () => {},
              ),
            ),
            const SizedBox(height: 80.0),
          ],
        ),
      ),
    );
  }
}

class OnboardingPage2 extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final OnboardingData data;
  OnboardingPage2({
    super.key,
    required this.data,
    required this.formKey,
  });

  final Set<String> _selectedTopics = {};
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
    return Form(
      key: formKey,
      child: Column(
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
          const SizedBox(height: 10.0),
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
                              _selectedTopics.clear();
                              _selectedTopics.addAll(selected);
                            },
                            validator: (selected) {
                              if (selected!.isEmpty) {
                                return 'Please select at least one topic';
                              }
                              return null;
                            },
                            onSaved: (Set<String>? newValue) {
                              data.topics = newValue;
                            },
                          );
                        }),
                  ),
                  const SizedBox(height: 80.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OnboardingPage3 extends StatelessWidget {
  final OnboardingData data;
  const OnboardingPage3({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Onboarding Page 3'),
    );
  }
}
