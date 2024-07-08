import 'package:flutter/material.dart';
import '../text_theme_extension.dart';

class EleaTextBox extends StatefulWidget {
  final String? labelText;
  final String? labelSubtext;
  final String? initialValue;
  final String? defaultErrorMessage;
  final bool? obscureText;
  final TextInputType? textInputType;
  final FormFieldSetter<String>? onSaved;
  final FormFieldSetter<String>? onChanged;
  final String? Function(String?)? onValidate;
  const EleaTextBox({
    super.key,
    this.labelText,
    this.labelSubtext,
    this.initialValue = "",
    this.onSaved,
    this.onChanged,
    this.onValidate,
    this.obscureText = false,
    this.defaultErrorMessage,
    this.textInputType = TextInputType.text,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EleaTextBoxState createState() => _EleaTextBoxState();
}

class _EleaTextBoxState extends State<EleaTextBox> {
  bool isInputValid = false;
  bool validated = false;
  String? errorMessage;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.onValidate != null) {
      errorMessage = widget.onValidate!(widget.initialValue);
    }
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
              color: Colors.grey[300]!,
              width: 1.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  keyboardType: widget.textInputType,
                  initialValue: widget.initialValue,
                  obscureText: widget.obscureText!,
                  onSaved: (text) {
                    if (widget.onSaved != null) {
                      widget.onSaved!(text);
                    }
                  },
                  onChanged: (text) {
                    if (widget.onChanged != null) {
                      widget.onChanged!(text);
                    }
                    if (widget.onValidate != null) {
                      setState(() {
                        errorMessage = widget.onValidate!(text);
                      });
                    }
                  },
                  validator: (value) {
                    setState(() {
                      validated = true;
                      if (widget.onValidate != null) {
                        errorMessage = widget.onValidate!(value);
                      }
                    });
                    return errorMessage;
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
                visible: validated && errorMessage == null,
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                ),
              ),
              Visibility(
                visible: validated && errorMessage != null,
                child: const Icon(
                  Icons.error,
                  color: Colors.red,
                ),
              ),
            ],
          ),
        ),
        if (validated && errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              widget.defaultErrorMessage != null
                  ? widget.defaultErrorMessage!
                  : errorMessage!,
              style: Theme.of(context).textTheme.errorText,
            ),
          ),
      ],
    );
  }
}
