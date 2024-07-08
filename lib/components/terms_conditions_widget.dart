import 'package:flutter/material.dart';
import 'package:elea_chat/components/custom_circular_checkbox.dart';
import '../text_theme_extension.dart';

class TermsConditionsWidget extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final bool initialValue;
  final void Function() onSubmit;

  TermsConditionsWidget({
    required this.formKey,
    required this.onSubmit,
    required this.initialValue,
  });

  @override
  _TermsConditionsWidgetState createState() => _TermsConditionsWidgetState();
}

class _TermsConditionsWidgetState extends State<TermsConditionsWidget> {
  bool _agreedToTOS = false;

  void _setAgreedToTOS(bool newValue) {
    setState(() {
      _agreedToTOS = newValue;
    });
  }

  void _showTermsAndConditions() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Terms and Conditions'),
        content: SingleChildScrollView(
          child: Text('Here are the terms and conditions...'),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    if (widget.formKey.currentState!.validate()) {
      widget.onSubmit();
    }
  }

  @override
  void initState() {
    super.initState();
    _agreedToTOS = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return FormField<bool>(
      initialValue: _agreedToTOS,
      validator: (value) {
        if (!value!) {
          return 'You must agree to the terms and conditions';
        }
        return null;
      },
      builder: (FormFieldState<bool> state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: GestureDetector(
                    onTap: _showTermsAndConditions,
                    child: Text(
                      'I agree to the Terms and Conditions',
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                ),
                CustomCircularCheckbox(
                  value: _agreedToTOS,
                  onChanged: (bool? newValue) {
                    _setAgreedToTOS(newValue!);
                    state.didChange(newValue); // Update the FormField state
                  },
                ),
              ],
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  state.errorText ?? '',
                  style: Theme.of(context).textTheme.errorText,
                ),
              ),
          ],
        );
      },
    );
  }
}
