import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/post_provider.dart'; // New import
import 'theme.dart'; // Custom theme for white base with cowboy accents
import 'screens/home_screen.dart'; // New import for extracted HomeScreen
import 'dart:io'; // Added for platform checks

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Conditionally initialize Firebase only on supported platforms (e.g., Android, iOS)
  if (!Platform.isLinux) {
    await Firebase.initializeApp();
  }
  runApp(const GuestApp());
}

class GuestApp extends StatelessWidget {
  const GuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<PostProvider>(
      create: (_) => PostProvider(),
      child: MaterialApp(
        title: 'Katy TX Guest App',
        theme: getAppTheme(), // Apply custom theme
        home: const HomeScreen(),
      ),
    );
  }
}
