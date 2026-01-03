import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

// NO extra import needed — MyApp is defined below in this same file

void main() {
  // Show Flutter framework errors on screen in release mode
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    FlutterError.dumpErrorToConsole(details, forceReport: true);
  };

  // Catch native/platform exceptions
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stack,
      library: 'platform dispatcher',
    ));
    return true;
  };

  // Critical: Catch unhandled async errors (most common cause of black screens)
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // If you have any async setup (e.g. dotenv.load(), SharedPreferences, etc.)
    // do it here before runApp

    runApp(const MyApp());
  }, (Object error, StackTrace stack) {
    FlutterError.reportError(FlutterErrorDetails(
      exception: error,
      stack: stack,
      context: ErrorDescription('in runZonedGuarded'),
    ));
    debugPrint('Uncaught async error: $error\n$stack');
  });
}

// Your original MyApp class — keep everything you already had here
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brubaker Home App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // your theme settings
      ),
      home: /* Your root widget, e.g. HomeScreen(), FlameGameWidget, etc. */,
    );
  }
}