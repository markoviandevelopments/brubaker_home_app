import 'package:flutter/material.dart';

ThemeData getAppTheme() {
  return ThemeData.dark().copyWith(
    primaryColor: const Color(0xFF00FFFF),
    scaffoldBackgroundColor: const Color(0xFF0A0A1E),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontFamily: 'Courier',
      ),
    ),
    colorScheme: ColorScheme.fromSwatch().copyWith(
      secondary: const Color(0xFFFF00FF),
      background: const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF0A0A1E), Color(0xFF1A1A3A)],
      ).colors[0],
    ),
    textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.white70)),
    iconTheme: const IconThemeData(color: Color(0xFF00FFFF)),
  );
}
