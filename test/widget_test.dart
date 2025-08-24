// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:brubaker_homeapp/main.dart'; // Import GuestApp
import 'package:brubaker_homeapp/theme.dart'; // Corrected import for theme

void main() {
  testWidgets('App launches with GuestApp and HomeScreen', (
    WidgetTester tester,
  ) async {
    // Build our app with the theme and trigger a frame.
    await tester.pumpWidget(GuestApp());

    // Verify that the HomeScreen loads and displays the title 'Toad Jumper'.
    expect(find.text('Toad Jumper'), findsOneWidget);

    // Verify the bottom navigation bar is present.
    expect(find.byType(BottomNavigationBar), findsOneWidget);

    // Verify the theme is applied (e.g., check AppBar title style).
    final appBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(
      appBar.titleTextStyle!.fontFamily,
      equals('Courier'),
    ); // From theme.dart
  });
}
