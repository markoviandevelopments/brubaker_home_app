import 'package:flutter/material.dart';

ThemeData getAppTheme() {
  return ThemeData(
    primaryColor: const Color(0xFF8B4513), // Saddle brown for cowboy nods
    scaffoldBackgroundColor: Colors.white, // Bright, clean white base
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0, // Modern, flat look
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
      ),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: const Color(0xFFCD5C5C), // Indian red for subtle Texas accents
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.black87), // Professional readability
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF8B4513),
    ), // Brown icons for theme tie-in
  );
}
