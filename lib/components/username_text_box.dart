import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../text_theme_extension.dart';

class UsernameTextBox extends StatefulWidget {
  final String? labelText;
  final String? labelSubtext;
  final String? initialValue;
  final String? currentUsername;
  final bool? obscureText;
  final FormFieldSetter<String>? onSaved;
  final FormFieldSetter<String>? onChanged;
  const UsernameTextBox({
    super.key,
    this.labelText,
    this.labelSubtext,
    this.initialValue,
    this.currentUsername,
    this.onSaved,
    this.onChanged,
    this.obscureText = false,
  });

  @override
  // ignore: library_private_types_in_public_api
  _UsernameTextBoxState createState() => _UsernameTextBoxState();
}

class _UsernameTextBoxState extends State<UsernameTextBox> {
  final TextEditingController _usernameController = TextEditingController();
  bool _isUsernameUnique = true;
  bool isInputValid = false;
  bool validated = false;
  String errorMessage = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _usernameController.text = widget.initialValue!;
    isInputValid =
        widget.initialValue != null && widget.initialValue!.isNotEmpty;
  }

  Future<bool> _checkUsernameUnique(String username) async {
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('username', isEqualTo: username)
        .get();
    return querySnapshot.docs.isEmpty;
  }

  void _validateUsername() async {
    final username = _usernameController.text;
    final isUnique = await _checkUsernameUnique(username);
    setState(() {
      _isUsernameUnique = isUnique;
      isInputValid = username.isNotEmpty && _isUsernameUnique;
      if (widget.currentUsername != null) {
        if (username == widget.currentUsername) {
          isInputValid = true;
        }
      }
      errorMessage = _isUsernameUnique
          ? "Please choose a user name."
          : "Username already exists";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labelText != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(widget.labelText!,
                style: Theme.of(context).textTheme.labelLarge),
          ),
        if (widget.labelSubtext != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(widget.labelSubtext!,
                style: Theme.of(context).textTheme.labelMedium,
                textAlign: TextAlign.left),
          ),
        if (widget.labelText != null || widget.labelSubtext != null)
          const SizedBox(height: 6.0),
        Container(
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: isInputValid ? Colors.green : Colors.grey[300]!,
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _usernameController,
                  obscureText: widget.obscureText!,
                  onSaved: (text) {
                    setState(() {
                      isInputValid = text!.isNotEmpty && _isUsernameUnique;
                      widget.onSaved!(text);
                    });
                  },
                  onChanged: (text) {
                    _validateUsername();
                    if (widget.onChanged != null) {
                      widget.onChanged!(text);
                    }
                  },
                  validator: (value) {
                    setState(() {
                      validated = true;
                    });
                    _validateUsername();
                    return isInputValid ? null : "error";
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    errorStyle: TextStyle(
                      height: 0.01,
                      color: Colors.transparent,
                    ),
                  ),
                ),
              ),
              Visibility(
                visible: validated && isInputValid,
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              Visibility(
                visible: validated && !isInputValid,
                child: const Icon(
                  Icons.error,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        if (!isInputValid)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(errorMessage,
                style: Theme.of(context).textTheme.errorText),
          ),
      ],
    );
  }
}
