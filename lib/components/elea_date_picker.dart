import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants.dart';
import '../text_theme_extension.dart';

class DatePickerField extends StatefulWidget {
  final String? labelText;
  final String? labelSubtext;
  final String? initialValue;
  final FormFieldSetter<String>? onSaved;
  final FormFieldSetter<String>? onChanged;
  const DatePickerField({
    super.key,
    this.labelText,
    this.labelSubtext,
    this.initialValue,
    this.onChanged,
    this.onSaved,
  });

  @override
  // ignore: library_private_types_in_public_api
  _DatePickerFieldState createState() => _DatePickerFieldState();
}

class _DatePickerFieldState extends State<DatePickerField> {
  late TextEditingController _dateController = TextEditingController();
  bool isInputValid = false;
  bool validated = false;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    DateTime initialDate = DateTime.now();
    if (_dateController.text.isNotEmpty) {
      initialDate = DateFormat('dd/MM/yyyy').parse(_dateController.text);
    }

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 1),
      locale: const Locale('en', 'GB'),
    );

    if (pickedDate != null) {
      String formattedDate = DateFormat('dd/MM/yyyy').format(pickedDate);
      setState(() {
        _dateController.text = formattedDate;
        isInputValid = true;
      });
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
          decoration: Constants.circularBorderBoxDecoration,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => _selectDate(context),
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: _dateController,
                      decoration: const InputDecoration(
                        hintText: 'DD/MM/YYYY',
                        border: InputBorder.none,
                        errorStyle: TextStyle(
                          height: 0.01,
                          color: Colors.transparent,
                        ),
                      ),
                      validator: (value) {
                        setState(
                          () {
                            validated = true;
                            isInputValid = value!.isNotEmpty;
                            errorMessage = isInputValid
                                ? null
                                : "Please select a date of birth";
                          },
                        );
                        return errorMessage;
                      },
                      onSaved: (text) {
                        setState(() {
                          widget.onSaved!(text);
                        });
                      },
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
        if (validated && errorMessage != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0),
            child: Text(
              errorMessage!,
              style: Theme.of(context).textTheme.errorText,
            ),
          ),
      ],
    );
  }
}
