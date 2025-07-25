import 'package:flutter/material.dart';
import 'theme.dart'; // Custom theme for white base with cowboy accents
import 'screens/eat_screen.dart';
import 'screens/visit_screen.dart';
import 'screens/scroll_screen.dart';
import 'screens/info_screen.dart';
import 'screens/games_screen.dart';

void main() {
  runApp(const GuestApp());
}

class GuestApp extends StatelessWidget {
  const GuestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Katy TX Guest App',
      theme: getAppTheme(), // Apply custom theme
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  static const List<Widget> _pages = <Widget>[
    EatScreen(),
    VisitScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.restaurant), label: 'Eat'),
          BottomNavigationBarItem(icon: Icon(Icons.place), label: 'Visit'),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome), // Sparkle for Scroll
            label: 'Scroll',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'Info'),
          BottomNavigationBarItem(icon: Icon(Icons.games), label: 'Fun'),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(
          context,
        ).colorScheme.secondary, // Red accent
        unselectedItemColor: Theme.of(
          context,
        ).primaryColor, // Brown for cowboy nod
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed, // Clean layout for 5 items
      ),
    );
  }
}
