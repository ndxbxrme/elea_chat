import 'package:flutter/material.dart';
import 'constants.dart';

extension CustomTextTheme on TextTheme {
  TextStyle get errorText => TextStyle(
        color: Colors.red,
        fontSize: 12.0,
        fontWeight: FontWeight.bold,
      );

  TextStyle get bodyLargeGrey => TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      height: 1.5,
      color: Color.fromARGB(255, 161, 175, 175));
}
