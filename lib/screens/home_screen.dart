import 'package:flutter/material.dart';
import 'led_controls_screen.dart';
import 'elements_screen.dart';
import 'scroll_screen.dart';
import 'info_screen.dart';
import 'games_screen.dart';
import 'star_field.dart'; // Import the new StarField widget

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 4;

  static const List<Widget> _pages = <Widget>[
    LedControlsScreen(),
    ElementsScreen(),
    ScrollScreen(),
    InfoScreen(),
    GamesScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Starry background effect
          Positioned.fill(child: StarField()),
          IndexedStack(index: _selectedIndex, children: _pages),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.widgets), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: '',
          ), // Changed to heart
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports),
            label: '',
          ), // Changed to esports
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor, // Neon cyan
        unselectedItemColor: Theme.of(context).colorScheme.secondary, // Magenta
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: const Color(0xFF0A0A1E), // Match dark space theme
      ),
    );
  }
}
