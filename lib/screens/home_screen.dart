import 'package:flutter/material.dart';
import 'package:brubaker_homeapp/screens/led_controls_screen.dart';
import 'package:brubaker_homeapp/screens/scroll_screen.dart';
import 'package:brubaker_homeapp/screens/info_screen.dart';
import 'package:brubaker_homeapp/screens/games_screen.dart';
import 'package:brubaker_homeapp/screens/socket_game_screen.dart';
import 'package:brubaker_homeapp/screens/cosmic_name_screen.dart';
import 'package:brubaker_homeapp/screens/minesweeper_screen.dart';
import 'package:brubaker_homeapp/screens/toad_jumper_screen.dart';
import 'package:brubaker_homeapp/screens/elements_screen.dart';
import 'package:brubaker_homeapp/screens/galactic_codebreaker_screen.dart';
import 'package:brubaker_homeapp/screens/star_field.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  int _gameScreenIndex =
      0; // Track the current game screen (0 = GamesScreen, 1 = Elements, 2 = ToadJumper, 3 = SocketGame, 4 = CosmicName, 5 = Minesweeper, 6 = Codebreaker)
  final List<Widget> _mainPages = [
    LedControlsScreen(onGameSelected: (index) {}),
    GamesScreen(onGameSelected: (index) {}),
    const ScrollScreen(),
    const InfoScreen(),
  ];
  late List<Widget> _gamePages;

  @override
  void initState() {
    super.initState();
    _gamePages = [
      GamesScreen(onGameSelected: _selectGame),
      ElementsScreen(onGameSelected: _selectGame),
      ToadJumperScreen(onGameSelected: _selectGame),
      SocketGameScreen(onGameSelected: _selectGame),
      CosmicNameScreen(onGameSelected: _selectGame),
      MinesweeperScreen(onGameSelected: _selectGame),
      GalacticCodebreakerScreen(onGameSelected: _selectGame),
    ];
    _mainPages[1] = _gamePages[0];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      if (index != 1) {
        _gameScreenIndex = 0;
      }
    });
  }

  void _selectGame(int gameIndex) {
    setState(() {
      if (gameIndex >= 0 && gameIndex < _gamePages.length) {
        _selectedIndex = 1;
        _gameScreenIndex = gameIndex;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: StarField(opacity: 0.3, offset: 0.0)),
          IndexedStack(
            index: _selectedIndex,
            children: _mainPages.map((page) {
              if (page is GamesScreen) {
                return _gamePages[_gameScreenIndex];
              }
              return page;
            }).toList(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.sports_esports), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.auto_awesome), label: ''),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: ''),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromARGB(255, 255, 225, 0),
        unselectedItemColor: const Color(0xFFFF4500),
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        backgroundColor: const Color(0xFF0A0A1E),
      ),
    );
  }
}
