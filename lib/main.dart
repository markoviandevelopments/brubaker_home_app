// lib/main.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'theme.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BrubakerApp());
}

/// Root widget – renamed to something that actually matches your app
class BrubakerApp extends StatelessWidget {
  const BrubakerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          return MaterialApp(
            title: 'Brubaker Home',
            theme: themeProvider.currentTheme,
            debugShowCheckedModeBanner: false,
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
