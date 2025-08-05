import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:animate_do/animate_do.dart';

class MinesweeperScreen extends StatefulWidget {
  const MinesweeperScreen({super.key});

  @override
  _MinesweeperScreenState createState() => _MinesweeperScreenState();
}

class _MinesweeperScreenState extends State<MinesweeperScreen> {
  Socket? _socket;
  List<List<dynamic>> _board = [];
  String _status = 'ongoing';
  int _width = 10;
  int _height = 10;
  int _mines = 10;
  String _errorMessage = '';
  bool _isLoading = false;
  String _buffer = '';

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  Future<void> _connectToServer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      _socket = await Socket.connect('108.254.1.184', 5091);
      _socket!.listen(
        (List<int> data) {
          _buffer += utf8.decode(data);
          var lines = _buffer.split('\n');
          for (int i = 0; i < lines.length - 1; i++) {
            var line = lines[i].trim();
            if (line.isEmpty) continue;
            try {
              final jsonData = jsonDecode(line);
              if (jsonData['type'] == 'state') {
                setState(() {
                  _board = (jsonData['board'] as List)
                      .map((row) => (row as List).cast<dynamic>())
                      .toList();
                  _status = jsonData['status'];
                  _width = jsonData['width'];
                  _height = jsonData['height'];
                  _mines = jsonData['mines'];
                });
              }
            } catch (e) {
              setState(() {
                _errorMessage = 'Error parsing data: $e';
              });
            }
          }
          _buffer = lines.last;
        },
        onError: (error) {
          setState(() {
            _errorMessage = 'Socket error: $error';
          });
          _disconnect();
        },
        onDone: () {
          _disconnect();
        },
      );
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  void _disconnect() {
    _socket?.destroy();
    _socket = null;
    if (mounted) {
      setState(() {
        _board = [];
      });
    }
  }

  void _sendAction(Map<String, dynamic> action) {
    if (_socket != null) {
      _socket!.write('${jsonEncode(action)}\n');
    }
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  Widget _buildCell(int row, int col) {
    final value = _board[row][col];
    IconData? icon;
    String text = '';
    Color cellColor = Colors.grey[300]!;
    Color textColor = Colors.black;

    if (value == 'hidden') {
      cellColor = const Color(0xFFD2B48C); // Tan for cowboy aesthetic
    } else if (value == 'flag') {
      icon = Icons.flag;
      cellColor = const Color(0xFFFFD700); // Gold for flags
    } else if (value == 'mine') {
      icon = Icons.warning;
      cellColor = const Color(0xFFB22222); // Firebrick red for mines
    } else if (value is int) {
      text = value > 0 ? value.toString() : '';
      cellColor = const Color(0xFF4682B4); // Steel blue for revealed cells
      if (value == 1) textColor = Colors.blue;
      if (value == 2) textColor = Colors.green;
      if (value == 3) textColor = Colors.red;
      if (value == 4) textColor = Colors.purple;
      if (value == 5) textColor = Colors.brown;
      if (value == 6) textColor = Colors.teal;
      if (value == 7) textColor = Colors.black;
      if (value == 8) textColor = Colors.grey;
    }

    return GestureDetector(
      onTap: () {
        if (_status == 'ongoing' && value == 'hidden') {
          _sendAction({'action': 'click', 'x': col, 'y': row});
        }
      },
      onLongPress: () {
        if (_status == 'ongoing' && (value == 'hidden' || value == 'flag')) {
          _sendAction({'action': 'flag', 'x': col, 'y': row});
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cellColor,
          border: Border.all(
            color: const Color(0xFF8B4513),
            width: 2,
          ), // Saddle brown border
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(2, 2),
            ),
          ],
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.black, size: 24)
              : Text(
                  text,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    fontFamily: 'RobotoMono', // Clean, modern font
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    String message = _status == 'win'
        ? 'You Won!'
        : _status == 'lose'
        ? 'Game Over!'
        : 'Mines: $_mines';
    Color bgColor = _status == 'win'
        ? const Color(0xFF228B22) // Forest green for win
        : _status == 'lose'
        ? const Color(0xFFB22222) // Firebrick red for lose
        : const Color(0xFFE0E0E0); // Light grey for ongoing

    return FadeIn(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        margin: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF8B4513), width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'RobotoMono',
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: const Color(0xFF8B4513), // Saddle brown accent
        scaffoldBackgroundColor: Colors.white, // Clean white background
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4682B4), // Steel blue button
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontFamily: 'Poppins', // Modern font
              fontWeight: FontWeight.bold,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8), // Softer corners
              side: const BorderSide(color: Color(0xFF8B4513), width: 1),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8B4513), // Saddle brown app bar
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
            fontFamily: 'Poppins',
          ),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(title: const Text('Minesweeper'), centerTitle: true),
        body: SafeArea(
          child: Column(
            children: [
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Color(0xFFB22222),
                      fontFamily: 'RobotoMono',
                    ),
                  ),
                ),
              if (_isLoading || _board.isEmpty)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _width,
                      childAspectRatio: 1,
                    ),
                    itemCount: _height * _width,
                    itemBuilder: (context, index) {
                      final row = index ~/ _width;
                      final col = index % _width;
                      return _buildCell(row, col);
                    },
                  ),
                ),
              _buildStatusMessage(),
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: ElevatedButton(
                  onPressed: () => _sendAction({'action': 'new_game'}),
                  child: const Text('Start New Game'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
