import 'package:flutter/material.dart';

class AppTheme {
  static const pink = Color(0xFFFF4F8B);
  static const purple = Color(0xFF7B2FF7);
  static const background = Color(0xFFFFE4EF);
  static const darkText = Color(0xFF211323);
  static const mutedText = Color(0xFF6B5D6B);
  static const softPurple = Color(0xFFF8F3FF);

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Arial',
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: pink,
        primary: purple,
        secondary: pink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: softPurple,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}