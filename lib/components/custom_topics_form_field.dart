import 'package:flutter/material.dart';
import '../constants.dart';

class CustomTopicsFormField extends FormField<Set<String>> {
  CustomTopicsFormField({
    super.key,
    required List<String> topics,
    required Set<String> selectedTopics,
    required FormFieldSetter<Set<String>> onSaved,
    required FormFieldValidator<Set<String>> validator,
    required ValueChanged<Set<String>> onChanged,
  }) : super(
          onSaved: onSaved,
          validator: validator,
          initialValue: selectedTopics,
          builder: (FormFieldState<Set<String>> state) {
            return TopicsSelector(
              topics: topics,
              selectedTopics: state.value!,
              onChanged: (selected) {
                state.didChange(selected);
                onChanged(selected);
              },
              errorText: state.errorText,
            );
          },
        );
}

class TopicsSelector extends StatelessWidget {
  final List<String> topics;
  final Set<String> selectedTopics;
  final ValueChanged<Set<String>> onChanged;
  final String? errorText;

  const TopicsSelector({
    super.key,
    required this.topics,
    required this.selectedTopics,
    required this.onChanged,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              errorText!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        Wrap(
          spacing: 6.0,
          runSpacing: 6.0,
          alignment: WrapAlignment.center,
          children: topics.map((topic) {
            bool isSelected = selectedTopics.contains(topic);
            return GestureDetector(
              onTap: () {
                Set<String> newSelectedTopics = Set.from(selectedTopics);
                if (isSelected) {
                  newSelectedTopics.remove(topic);
                } else {
                  newSelectedTopics.add(topic);
                }
                onChanged(newSelectedTopics);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                    vertical: 10.0, horizontal: 20.0),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Constants.toggleSelectedBgColor
                      : Constants.toggleDefaultBgColor,
                  borderRadius: BorderRadius.circular(20.0),
                  border: Border.all(color: Colors.grey),
                ),
                child: Text(
                  topic,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
