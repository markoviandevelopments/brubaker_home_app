import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:confetti/confetti.dart';

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
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
    _connectToServer();
  }

  Future<void> _connectToServer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      _socket = await Socket.connect('192.168.1.126', 5091);
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
                  if (_status == 'win') {
                    _confettiController.play();
                  }
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
    _confettiController.dispose();
    _disconnect();
    super.dispose();
  }

  Widget _buildCell(int row, int col) {
    final value = _board[row][col];
    IconData? icon;
    String text = '';
    Color cellColor = const Color(0xFFD2B48C); // Tan base color
    Color textColor = Colors.black;

    if (value == 'hidden') {
      cellColor = const Color(0xFFD2B48C);
    } else if (value == 'flag') {
      icon = Icons.flag;
      cellColor = const Color(0xFFFFD700);
    } else if (value == 'mine') {
      icon = Icons.warning;
      cellColor = const Color(0xFFB22222);
    } else if (value is int) {
      text = value > 0 ? value.toString() : '';
      cellColor = const Color(0xFF4682B4);
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
      child: ZoomIn(
        duration: const Duration(milliseconds: 200),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cellColor, cellColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: const Color(0xFF8B4513), width: 2),
            borderRadius: BorderRadius.circular(4),
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
                ? Icon(icon, color: Colors.black, size: 26)
                : Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      fontFamily: 'RobotoMono',
                    ),
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
        ? const Color(0xFF228B22)
        : _status == 'lose'
        ? const Color(0xFFB22222)
        : const Color(0xFFE0E0E0);

    return FadeIn(
      duration: const Duration(milliseconds: 500),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF8B4513), width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          message,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'RobotoMono',
            letterSpacing: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildWinOverlay() {
    return _status == 'win'
        ? FadeIn(
            duration: const Duration(milliseconds: 500),
            child: Stack(
              children: [
                Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElasticIn(
                          duration: const Duration(milliseconds: 800),
                          child: const Text(
                            'YOU WON!',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFFD700),
                              fontFamily: 'RobotoMono',
                              shadows: [
                                Shadow(
                                  color: Colors.black,
                                  blurRadius: 10,
                                  offset: Offset(2, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            _confettiController.stop();
                            _sendAction({'action': 'new_game'});
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4682B4),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 32,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(
                                color: Color(0xFF8B4513),
                                width: 2,
                              ),
                            ),
                          ),
                          child: const Text(
                            'Play Again',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'RobotoMono',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    colors: const [
                      Color(0xFFFFD700),
                      Color(0xFF4682B4),
                      Color(0xFF8B4513),
                    ],
                    emissionFrequency: 0.05,
                    numberOfParticles: 50,
                    maxBlastForce: 20,
                    minBlastForce: 10,
                  ),
                ),
              ],
            ),
          )
        : const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: const Color(0xFF8B4513),
        scaffoldBackgroundColor: const Color(0xFFF5F5DC),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF4682B4),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontFamily: 'RobotoMono',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0xFF8B4513), width: 2),
            ),
            elevation: 5,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8B4513),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'RobotoMono',
          ),
          elevation: 5,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Minesweeper'),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF8B4513), Color(0xFFA0522D)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        body: Stack(
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF5F5DC), Color(0xFFE6D7A8)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
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
                          fontSize: 16,
                        ),
                      ),
                    ),
                  if (_isLoading || _board.isEmpty)
                    const Expanded(
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF8B4513),
                              width: 4,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: GridView.builder(
                            padding: const EdgeInsets.all(4),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
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
                      ),
                    ),
                  _buildStatusMessage(),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: ElevatedButton(
                      onPressed: () {
                        _confettiController.stop();
                        _sendAction({'action': 'new_game'});
                      },
                      child: const Text('Start New Game'),
                    ),
                  ),
                ],
              ),
            ),
            _buildWinOverlay(),
          ],
        ),
      ),
    );
  }
}
