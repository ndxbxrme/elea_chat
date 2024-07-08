import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'constants.dart';
import 'text_theme_extension.dart';

const Color bgColor = Color(0xFFFFFCFB);

class ThemeController {
  static TextTheme get defaultTextTheme {
    return GoogleFonts.beVietnamProTextTheme(
      const TextTheme(
        headlineLarge:
            TextStyle(fontSize: 40, height: 1.3, color: Constants.textColor),
        headlineMedium:
            TextStyle(fontSize: 18, height: 1.3, color: Constants.textColor),
        headlineSmall:
            TextStyle(fontSize: 16, height: 1.3, color: Constants.textColor),
        titleLarge:
            TextStyle(fontSize: 22, height: 1.3, color: Constants.textColor),
        titleMedium:
            TextStyle(fontSize: 16, height: 1.3, color: Constants.textColor),
        titleSmall:
            TextStyle(fontSize: 13, height: 1.3, color: Color(0xFFA7A7A7)),
        bodyLarge: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            height: 1.5,
            color: Constants.textColor),
        bodyMedium:
            TextStyle(fontSize: 14, height: 1.5, color: Constants.textColor),
        bodySmall:
            TextStyle(fontSize: 12, height: 1.5, color: Constants.textColor),
        labelLarge:
            TextStyle(fontSize: 14, height: 1.5, color: Constants.textColor),
        labelMedium:
            TextStyle(fontSize: 12, height: 1.5, color: Constants.textColor),
        labelSmall:
            TextStyle(fontSize: 10, height: 1.5, color: Constants.textColor),
      ),
    );
  }

  static ThemeData lightTheme = ThemeData(
    textTheme: defaultTextTheme,
    colorScheme: const ColorScheme.light(
      background: Colors.white,
      primary: Constants.textColor,
      secondary: Colors.yellow,
    ),
    appBarTheme: AppBarTheme(backgroundColor: bgColor),
    iconTheme: IconThemeData(color: Constants.textColor),
  );
}
