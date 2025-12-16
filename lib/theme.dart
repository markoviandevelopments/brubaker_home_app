// lib/theme.dart

import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData get currentTheme => _galacticTheme;
}

ThemeData get _galacticTheme => ThemeData.dark().copyWith(
  primaryColor: const Color.fromARGB(255, 133, 0, 0),
  scaffoldBackgroundColor: const Color(0xFF0A0A1E),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.transparent,
    elevation: 0,
  ),
  colorScheme: const ColorScheme.dark().copyWith(
    secondary: Color(0xFFFF00FF),
    surface: Color(0xFF1A1A3A),
  ),
  textTheme: const TextTheme(bodyLarge: TextStyle(color: Colors.white70)),
  iconTheme: const IconThemeData(color: Color.fromARGB(255, 150, 0, 0)),
);
