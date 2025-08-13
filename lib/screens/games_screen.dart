import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Added for Orbitron font
import 'star_field.dart'; // Updated to use StarField
import 'led_controls_screen.dart';
import 'socket_game_screen.dart';
import 'indian_name_screen.dart';
import 'minesweeper_screen.dart';
import 'elements_screen.dart';

class GamesScreen extends StatelessWidget {
  const GamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A1E), // Dark space background
              Color(0xFF1A1A3A),
            ],
          ),
        ),
        child: Stack(
          children: [
            // Starry particle effect
            Positioned.fill(child: StarField()),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    _buildGameButton(
                      context,
                      title: 'Socket Game (Meow)',
                      color: const Color(0xFF00FFFF), // Neon cyan
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SocketGameScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGameButton(
                      context,
                      title: 'Silly Name',
                      color: const Color(0xFF8B0000), // Deep red
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const IndianNameScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGameButton(
                      context,
                      title: 'Minesweeper',
                      color: const Color(0xFFFFFF00), // Neon yellow
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MinesweeperScreen(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGameButton(
                      context,
                      title: 'Elements',
                      color: const Color(0xFF4B0082), // Deep purple
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ElementsScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameButton(
    BuildContext context, {
    required String title,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 200,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color.withOpacity(0.8),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color, width: 2),
          ),
          elevation: 5,
          shadowColor: color.withOpacity(0.5),
        ),
        child: Text(
          title,
          style: GoogleFonts.orbitron(
            // Changed to Orbitron font
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
