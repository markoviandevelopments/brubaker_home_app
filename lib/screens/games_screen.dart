import 'package:flutter/material.dart';
import 'led_controls_screen.dart'; // New screen

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Coming Soon: Fun Texas-Themed Games!',
            style: TextStyle(fontSize: 18, color: Colors.black87),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const LedControlsScreen(),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
            ), // Brown cowboy accent
            child: const Text('LED Controls'),
          ),
        ],
      ),
    );
  }
}
