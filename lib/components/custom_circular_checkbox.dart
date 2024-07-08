import 'package:elea_chat/constants.dart';
import 'package:flutter/material.dart';

class CustomCircularCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  CustomCircularCheckbox({required this.value, required this.onChanged});

  @override
  State<CustomCircularCheckbox> createState() => _CustomCircularCheckboxState();
}

class _CustomCircularCheckboxState extends State<CustomCircularCheckbox> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        widget.onChanged(!widget.value);
      },
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Constants.toggleDefaultBgColor,
          border: Border.all(
            color: Colors.grey,
          ),
        ),
        width: 40,
        height: 40,
        child: widget.value
            ? Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 24,
              )
            : null,
      ),
    );
  }
}
