import 'package:flutter/material.dart';
import '../constants.dart';
import '../text_theme_extension.dart';

class EleaGenderSelector extends StatefulWidget {
  final String? labelText;
  final String? labelSubtext;
  final String? initialValue;
  final bool? obscureText;
  final FormFieldSetter<String>? onSaved;
  final FormFieldSetter<String>? onChanged;
  const EleaGenderSelector({
    super.key,
    this.labelText,
    this.labelSubtext,
    this.initialValue,
    this.onSaved,
    this.onChanged,
    this.obscureText = false,
  });

  @override
  // ignore: library_private_types_in_public_api
  _EleaGenderSelectorState createState() => _EleaGenderSelectorState();
}

class _EleaGenderSelectorState extends State<EleaGenderSelector> {
  bool isInputValid = false;

  @override
  Widget build(BuildContext context) {
    bool isInputValid =
        widget.initialValue != null && widget.initialValue!.isNotEmpty;
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
        CustomGenderFormField(
          parentContext: context,
          onSaved: widget.onSaved,
          initialValue: widget.initialValue,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a gender';
            }
            return null;
          },
        ),
      ],
    );
  }
}

class CustomGenderFormField extends FormField<String> {
  final BuildContext parentContext;
  CustomGenderFormField({
    super.key,
    super.onSaved,
    super.validator,
    super.initialValue,
    required this.parentContext,
    AutovalidateMode super.autovalidateMode = AutovalidateMode.disabled,
  }) : super(
          builder: (FormFieldState<String> state) {
            return GenderSelector(
              parentContext: parentContext,
              selectedGender: state.value ?? '',
              onChanged: (value) {
                state.didChange(value);
              },
              errorText: state.errorText,
            );
          },
        );
}

class GenderSelector extends StatelessWidget {
  final BuildContext parentContext;
  final String selectedGender;
  final ValueChanged<String> onChanged;
  final String? errorText;

  const GenderSelector({
    super.key,
    required this.selectedGender,
    required this.onChanged,
    required this.parentContext,
    this.errorText,
  });

  Widget _buildGenderOption(String gender) {
    bool isSelected = selectedGender == gender;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          FocusScope.of(parentContext).unfocus();
          onChanged(gender);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
          decoration: BoxDecoration(
            color: isSelected
                ? Constants.toggleSelectedBgColor
                : Constants.toggleDefaultBgColor,
            borderRadius: BorderRadius.circular(30.0),
            border: Border.all(
              color: Colors.grey,
            ),
          ),
          child: Center(
            child: Text(
              gender,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildGenderOption('Male'),
            const SizedBox(width: 10.0),
            _buildGenderOption('Female'),
            const SizedBox(width: 10.0),
            _buildGenderOption('Other'),
          ],
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              errorText!,
              style: Theme.of(context).textTheme.errorText,
            ),
          ),
      ],
    );
  }
}
