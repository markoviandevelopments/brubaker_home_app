import 'package:flutter/material.dart';
import 'led_controls_screen.dart'; // New screen
import 'socket_game_screen.dart'; // New screen
import 'indian_name_screen.dart'; // New screen
import 'minesweeper_screen.dart'; // New screen

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
          const SizedBox(height: 10), // Margin
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SocketGameScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink(600),
            ),
            child: const Text('Socket Game (meow)'),
          ),
          const SizedBox(height: 10), // Margin
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const IndianNameScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueGrey,
            ),
            child: const Text('Indian Name'),
          ),
          const SizedBox(height: 10), // Margin
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const MinesweeperScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red(900),
            ),
            child: const Text('Minesweeper'),
          ),
          const SizedBox(height: 10), // Margin
        ],
      ),
    );
  }
}