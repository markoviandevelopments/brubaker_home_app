import 'package:flutter/material.dart';

class EventsScreen extends StatelessWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A1E), Color(0xFF1A1A3A)],
          ),
        ),
        child: const Center(
          child: Text(
            'Local Events Coming Soon!',
            style: TextStyle(
              fontFamily: 'Courier',
              fontSize: 18,
              color: Colors.white70,
            ),
          ),
        ),
      ),
    );
  }
}
