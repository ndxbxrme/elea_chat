import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../components/elea_text_box.dart';
import '../constants.dart';
import '../validators.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _email = "";
  String _password = "";
  String? _loginError;
  _validateAndSave() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
      } on Exception catch (e) {
        // TODO
        setState(() {
          _loginError = "Unrecognized email or password.";
        });
      }
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Center(
          child:
              Text('Login', style: Theme.of(context).textTheme.headlineMedium),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_loginError != null)
                Padding(
                  padding: Constants.horizontalPadding,
                  child: Text(_loginError!),
                ),
              Padding(
                padding: Constants.horizontalPadding,
                child: EleaTextBox(
                  labelText: 'Email address',
                  textInputType: TextInputType.emailAddress,
                  onSaved: (value) => _email = value!,
                  onValidate: Validators.validateEmail,
                  defaultErrorMessage: "Please enter your email address.",
                  initialValue: _email,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: Constants.horizontalPadding,
                child: EleaTextBox(
                  labelText: 'Password',
                  obscureText: true,
                  onSaved: (value) => _password = value!,
                  onValidate: Validators.validatePassword,
                  initialValue: _password,
                ),
              ),
              const SizedBox(height: 20),
              // Button to navigate to SignupScreen
              ElevatedButton(
                onPressed: () async {
                  // Navigate to SignupScreen when the button is pressed
                  _validateAndSave();
                },
                child: const Text('Log In'),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => SignupScreen()));
                },
                child: Text("Sign up"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
