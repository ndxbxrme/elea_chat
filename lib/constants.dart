import 'package:flutter/material.dart';

class Constants {
  static const EdgeInsets horizontalPadding =
      EdgeInsets.symmetric(horizontal: 20);
  //colours
  static const Color textColor = Color(0xFF084848);
  static const Color bgColor = Color(0xFFFFF9F6);
  static const Color orangeColor = Color(0xFFFF8A49);
  static const Color toggleDefaultBgColor = Color(0xFFFCF5F0);
  static const Color toggleSelectedBgColor = Color(0xFFB0CFFF);
  static const Color toggleAllBgColor = Color(0xFF084848);
  static const Color borderColor = Color(0xFFDFDFDF);
  static BoxDecoration circularBorderBoxDecoration = BoxDecoration(
    borderRadius: BorderRadius.circular(25),
    border: Border.all(
      color: Constants.borderColor!,
      width: 1.0,
    ),
  );

  static final ButtonStyle orangeButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Constants.orangeColor,
    foregroundColor: Colors.white,
    textStyle: const TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.30,
    ),
    minimumSize: const Size(100, 50),
  );
  static final ButtonStyle outlineButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Constants.bgColor,
    textStyle: const TextStyle(
      color: Constants.textColor,
      fontSize: 20,
      fontWeight: FontWeight.w500,
      letterSpacing: -0.30,
    ),
    side: BorderSide(
      color: Colors.grey[600]!,
      width: 1.0,
    ),
    minimumSize: const Size(150, 50),
  );
}
