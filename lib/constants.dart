import 'package:flutter/material.dart';

class Constants {
  static const EdgeInsets horizontalPadding =
      EdgeInsets.symmetric(horizontal: 20);
  //colours
  static const Color textColor = Color(0xFF084848);
  static const Color bgColor = Color(0xFFFFFCFB);
  static const Color toggleDefaultBgColor = Color(0xFFFCF5F0);
  static const Color toggleSelectedBgColor = Color(0xFFB0CFFF);
  static BoxDecoration circularBorderBoxDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(25),
    border: Border.all(
      color: Colors.grey[600]!,
      width: 1.0,
    ),
  );
}
