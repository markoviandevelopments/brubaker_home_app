// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:brubaker_homeapp/theme.dart';

// Import all your screens (tunes & cosmic removed)
import 'led_controls_screen.dart';
import 'scroll_screen.dart';
import 'info_screen.dart';
import 'games_screen.dart';
import 'socket_game_screen.dart';
import 'minesweeper_screen.dart';
import 'toad_jumper_screen.dart';
import 'elements_screen.dart';
import 'galactic_codebreaker_screen.dart';

// Only the default galactic background
import 'star_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _gameScreenIndex = 0;

  late final List<Widget> _gamePages;

  @override
  void initState() {
    super.initState();
    _gamePages = [
      GamesScreen(onGameSelected: _selectGame), // 0: Games hub
      ElementsScreen(onGameSelected: _selectGame), // 1: Elements
      ToadJumperScreen(onGameSelected: _selectGame), // 2: Toad Jumper
      SocketGameScreen(onGameSelected: _selectGame), // 3: Socket Game
      MinesweeperScreen(onGameSelected: _selectGame), // 4: Minesweeper
      GalacticCodebreakerScreen(onGameSelected: _selectGame), // 5: Codebreaker
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 1)
        _gameScreenIndex = 0; // reset game sub-page when leaving Games tab
    });
  }

  void _selectGame(int gameIndex) {
    if (gameIndex >= 0 && gameIndex < _gamePages.length) {
      setState(() {
        _selectedIndex = 1;
        _gameScreenIndex = gameIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Use the app's theme colors directly – no holiday overrides
    final theme = Theme.of(context);
    final primaryGlow = theme.primaryColor;
    final secondaryGlow = theme.colorScheme.secondary;

    final List<Widget> pages = [
      const LedControlsScreen(), // 0
      _gamePages[_gameScreenIndex], // 1: Games or sub-game
      const ScrollScreen(), // 2
      const InfoScreen(), // 3
    ];

    return Scaffold(
      body: Container(
        // Simple dark-space gradient that matches the default galactic feel
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.scaffoldBackgroundColor, theme.colorScheme.surface],
          ),
        ),
        child: Stack(
          children: [
            // Default star field background (opacity tuned for subtlety)
            const Positioned.fill(child: StarField(opacity: 0.4)),

            // Consistent nebula glow using theme colors
            Positioned.fill(
              child: _NebulaBackground(
                primaryColor: primaryGlow,
                secondaryColor: secondaryGlow,
              ),
            ),

            // Main page content
            IndexedStack(index: _selectedIndex, children: pages),
          ],
        ),
      ),

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: primaryGlow.withOpacity(0.4),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: const Color.fromARGB(
            255,
            255,
            225,
            0,
          ), // classic golden yellow
          unselectedItemColor: const Color(0xFFFF4500), // bright orange-red
          backgroundColor: const Color(0xFF0A0A1E).withOpacity(0.9),
          type: BottomNavigationBarType.fixed,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.lightbulb),
              label: '',
            ), // 0: Lights
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_esports),
              label: '',
            ), // 1: Games
            BottomNavigationBarItem(
              icon: Icon(Icons.auto_awesome),
              label: '',
            ), // 2: Scroll
            BottomNavigationBarItem(
              icon: Icon(Icons.favorite),
              label: '',
            ), // 3: Info
          ],
        ),
      ),
    );
  }
}

// Reusable nebula glow – now always tied to the app theme
class _NebulaBackground extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;

  const _NebulaBackground({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NebulaPainter(
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
      ),
    );
  }
}

class _NebulaPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _NebulaPainter({required this.primaryColor, required this.secondaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.3),
          secondaryColor.withOpacity(0.2),
          Colors.transparent,
        ],
        center: const Alignment(0.3, 0.4),
        radius: 0.6,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..blendMode = BlendMode.overlay;

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.4),
      size.width * 0.6,
      paint,
    );

    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.7),
      size.width * 0.5,
      paint..color = primaryColor.withOpacity(0.25),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
