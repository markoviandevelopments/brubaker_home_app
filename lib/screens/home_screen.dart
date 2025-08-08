import 'package:flutter/material.dart';
import 'led_controls_screen.dart';
import 'events_screen.dart'; // Placeholder for Events screen
import 'scroll_screen.dart';
import 'info_screen.dart';
import 'games_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 4;

  static const List<Widget> _pages = <Widget>[
    LedControlsScreen(),
    EventsScreen(), // Replaced VisitScreen
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
      appBar: AppBar(title: const Text('Welcome to Katy, TX!')),
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: '',
          ), // Events icon
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: ''),
          BottomNavigationBarItem(
            icon: Icon(Icons.gamepad),
            label: '',
          ), // Gamepad for Fun
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).primaryColor, // Neon cyan
        unselectedItemColor: Theme.of(context).colorScheme.secondary, // Magenta
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false, // Hide labels
        showUnselectedLabels: false,
        backgroundColor: const Color(0xFF0A0A1E), // Match dark space theme
      ),
    );
  }
}
