import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../components/elea_text_box.dart';
import '../constants.dart';
import '../validators.dart';
import 'login_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String _email = "";
  String _password = "";
  String _password1 = "";
  String? _loginError;
  String? repeatPassword(String? value) {
    if (value == null || value.isEmpty) {
      return null;
    }
    if (_password != _password1) {
      return 'Passwords must match';
    }
    return null;
  }

  _validateAndSave(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        Navigator.pop(context);
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
      body: Form(
        key: _formKey,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Please Log In',
                  style: Theme.of(context).textTheme.bodyLarge),
              if (_loginError != null)
                Padding(
                  padding: Constants.horizontalPadding,
                  child: Text(_loginError!),
                ),
              SizedBox(height: 20),
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
                  onChanged: (value) => _password = value!,
                  onSaved: (value) => _password = value!,
                  onValidate: Validators.validatePassword,
                  initialValue: _password,
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: Constants.horizontalPadding,
                child: EleaTextBox(
                  labelText: 'Repeat Password',
                  obscureText: true,
                  onChanged: (value) => _password1 = value!,
                  onValidate: repeatPassword,
                  initialValue: _password1,
                ),
              ),
              const SizedBox(height: 20),
              // Button to navigate to SignupScreen
              ElevatedButton(
                onPressed: () async {
                  // Navigate to SignupScreen when the button is pressed
                  _validateAndSave(context);
                },
                child: const Text('Sign up'),
              ),
              const SizedBox(height: 20),
              InkWell(
                onTap: () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => LoginScreen()));
                },
                child: Text("Log in"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
