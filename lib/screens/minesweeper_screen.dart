import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/foundation.dart';

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
  bool _showWinOverlay = false;
  bool _showLoseOverlay = false;

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
                  if (kDebugMode) {
                    print('Game status: $_status');
                  }
                  _showWinOverlay = _isWinStatus();
                  _showLoseOverlay = _status.toLowerCase() == 'lose';
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

  bool _isWinStatus() {
    return ['win', 'victory', 'won', 'success'].contains(_status.toLowerCase());
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
    Color cellColor = const Color(
      0xFF1A1A3A,
    ).withOpacity(0.9); // Hidden: high-opacity navy for contrast
    Color textColor = Colors.white;
    double opacity = 0.9;

    if (value == 'hidden') {
      cellColor = const Color(0xFF1A1A3A); // Starry navy
    } else if (value == 'flag') {
      icon = Icons.star;
      cellColor = const Color(0xFF00FFFF).withOpacity(0.8);
      opacity = 0.8;
    } else if (value == 'mine') {
      icon = Icons.warning_amber;
      cellColor = const Color(0xFFFF00FF).withOpacity(1.0);
      opacity = 1.0;
    } else if (value is int) {
      text = value > 0 ? value.toString() : '';
      cellColor = const Color(
        0xFF0A0A1E,
      ).withOpacity(0.2); // Revealed: low-opacity dark for high contrast
      opacity = 0.2;
      if (value == 1) textColor = const Color(0xFF00FFFF);
      if (value == 2) textColor = const Color(0xFF00FF00);
      if (value == 3) textColor = const Color(0xFFFF00FF);
      if (value == 4) textColor = const Color(0xFF800080);
      if (value == 5) textColor = const Color(0xFFFFA500);
      if (value == 6) textColor = const Color(0xFF00FFFF);
      if (value == 7) textColor = Colors.white;
      if (value == 8) textColor = Colors.grey[300]!;
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
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3), // Clear glass blur
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cellColor, cellColor.withOpacity(opacity)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.4),
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFFF).withOpacity(0.2),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, color: Colors.white, size: 24)
                    : Text(
                        text,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          fontFamily: 'Courier',
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMessage() {
    String message = _isWinStatus()
        ? 'Galactic Victory!'
        : _status == 'lose'
        ? 'Black Hole Defeat!'
        : 'Mines: $_mines';
    Color bgColor = _isWinStatus()
        ? const Color(0xFF00FFFF).withOpacity(0.6)
        : _status == 'lose'
        ? const Color(0xFFFF00FF).withOpacity(0.6)
        : Colors.transparent;

    return FadeIn(
      duration: const Duration(milliseconds: 500),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontFamily: 'Courier',
                letterSpacing: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWinOverlay() {
    if (!_showWinOverlay) return const SizedBox.shrink();
    return SlideInDown(
      duration: const Duration(milliseconds: 600),
      child: FadeIn(
        duration: const Duration(milliseconds: 500),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Pulse(
                          duration: const Duration(milliseconds: 1000),
                          child: const Text(
                            'GALACTIC VICTORY!',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF00FFFF),
                              fontFamily: 'Courier',
                              shadows: [
                                Shadow(
                                  color: Color(0xFF00FFFF),
                                  blurRadius: 15,
                                  offset: Offset(0, 0),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            _sendAction({'action': 'new_game'});
                            setState(() => _showWinOverlay = false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00FFFF),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 32,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            elevation: 8,
                          ),
                          child: const Text(
                            'New Mission',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 30),
                onPressed: () => setState(() => _showWinOverlay = false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoseOverlay() {
    if (!_showLoseOverlay) return const SizedBox.shrink();
    return SlideInDown(
      duration: const Duration(milliseconds: 600),
      child: FadeIn(
        duration: const Duration(milliseconds: 500),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  color: Colors.black.withOpacity(0.7),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShakeX(
                          duration: const Duration(milliseconds: 800),
                          child: Flash(
                            duration: const Duration(milliseconds: 300),
                            child: const Text(
                              'BLACK HOLE DEFEAT!',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF00FF),
                                fontFamily: 'Courier',
                                shadows: [
                                  Shadow(
                                    color: Color(0xFFFF00FF),
                                    blurRadius: 15,
                                    offset: Offset(0, 0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton(
                          onPressed: () {
                            _sendAction({'action': 'new_game'});
                            setState(() => _showLoseOverlay = false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF00FF),
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 32,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(
                                color: Colors.white.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            elevation: 8,
                          ),
                          child: const Text(
                            'Retry Mission',
                            style: TextStyle(
                              fontSize: 20,
                              fontFamily: 'Courier',
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 30),
                onPressed: () => setState(() => _showLoseOverlay = false),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF00FFFF),
        scaffoldBackgroundColor: const Color(0xFF0A0A1E),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00FFFF),
            foregroundColor: Colors.black,
            textStyle: const TextStyle(
              fontFamily: 'Courier',
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: BorderSide(color: Colors.white.withOpacity(0.2), width: 2),
            ),
            elevation: 5,
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: Color(0xFF00FFFF),
            fontSize: 22,
            fontWeight: FontWeight.bold,
            fontFamily: 'Courier',
          ),
          elevation: 0,
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text('Galactic Minesweeper'),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A0A1E), Color(0xFF1A1A3A)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    if (_errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          _errorMessage,
                          style: const TextStyle(
                            color: Color(0xFFFF00FF),
                            fontFamily: 'Courier',
                            fontSize: 16,
                          ),
                        ),
                      ),
                    if (_isLoading || _board.isEmpty)
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF00FFFF),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.transparent, // Clear glass
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00FFFF,
                                      ).withOpacity(0.3),
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
                        ),
                      ),
                    _buildStatusMessage(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 40, top: 10),
                      child: ElevatedButton(
                        onPressed: () => _sendAction({'action': 'new_game'}),
                        child: const Text('New Mission'),
                      ),
                    ),
                  ],
                ),
                _buildWinOverlay(),
                _buildLoseOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
