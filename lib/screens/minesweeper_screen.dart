import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brubaker_homeapp/screens/star_field.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'dart:async';

class MinesweeperScreen extends StatefulWidget {
  final Function(int) onGameSelected; // Required for navigation

  const MinesweeperScreen({super.key, required this.onGameSelected});

  @override
  _MinesweeperScreenState createState() => _MinesweeperScreenState();
}

class _MinesweeperScreenState extends State<MinesweeperScreen> {
  Socket? _socket;
  StreamSubscription<List<int>>? _subscription;
  List<List<dynamic>> _board = [];
  String _status = 'ongoing';
  int _width = 10;
  int _height = 10;
  int _mines = 10;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isConnected = false;
  String _buffer = '';
  bool _showWinOverlay = false;
  bool _showLoseOverlay = false;

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _socket?.close();
    _socket = null;
    super.dispose();
  }

  Future<void> _connectToServer() async {
    await _disconnect();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      _socket = await Socket.connect(
        '108.254.1.184',
        5091,
      ).timeout(const Duration(seconds: 15));
      print('Connected to server at 108.254.1.184:5091');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isConnected = true;
        });
      }
      _subscription = _socket!.listen(
        (List<int> data) {
          if (!mounted) return;
          _buffer += utf8.decode(data, allowMalformed: true);
          print('Received data: $_buffer');
          var lines = _buffer.split('\n');
          for (int i = 0; i < lines.length - 1; i++) {
            var line = lines[i].trim();
            if (line.isEmpty) continue;
            print('Processing line: $line');
            try {
              final jsonData = jsonDecode(line);
              print('Parsed JSON: $jsonData');
              if (jsonData['type'] == 'state' && mounted) {
                setState(() {
                  _board = (jsonData['board'] as List)
                      .map((row) => (row as List).cast<dynamic>())
                      .toList();
                  _status = jsonData['status'] ?? 'ongoing';
                  _width = jsonData['width'] ?? 10;
                  _height = jsonData['height'] ?? 10;
                  _mines = jsonData['mines'] ?? 10;
                  _showWinOverlay = _isWinStatus();
                  _showLoseOverlay = _status.toLowerCase() == 'lose';
                  _isLoading = false;
                });
              } else {
                print('Ignoring non-state message: ${jsonData['type']}');
              }
            } catch (e, stackTrace) {
              _showErrorSnackBar('Error parsing server data: $e');
              print('Error parsing data: $e\nStack trace: $stackTrace');
            }
          }
          _buffer = lines.last;
        },
        onError: (error, stackTrace) {
          _showErrorSnackBar('Connection error: $error');
          print('Socket error: $error\nStack trace: $stackTrace');
          if (mounted) {
            setState(() {
              _isConnected = false;
              _board = _createFallbackBoard();
            });
          }
          _connectToServer();
        },
        onDone: () {
          _showErrorSnackBar('Server connection closed');
          print('Socket connection closed');
          if (mounted) {
            setState(() {
              _isConnected = false;
              _board = _createFallbackBoard();
            });
          }
          _connectToServer();
        },
        cancelOnError: true,
      );
    } catch (e, stackTrace) {
      _showErrorSnackBar('Failed to connect to server: $e');
      print('Connection error: $e\nStack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _isConnected = false;
          _board = _createFallbackBoard();
        });
      }
      _connectToServer();
    }
  }

  Future<void> _disconnect() async {
    if (_subscription != null) {
      await _subscription!.cancel();
      _subscription = null;
    }
    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }
    if (mounted) {
      setState(() {
        _isConnected = false;
        _isLoading = false;
        _errorMessage = '';
      });
    }
  }

  List<List<dynamic>> _createFallbackBoard() {
    print('Using fallback board');
    return List.generate(
      _height,
      (_) => List.generate(_width, (_) => 'hidden'),
    );
  }

  bool _isWinStatus() {
    return ['win', 'victory', 'won', 'success'].contains(_status.toLowerCase());
  }

  void _sendAction(Map<String, dynamic> action) {
    if (_socket != null && _isConnected && mounted) {
      try {
        final actionJson = jsonEncode(action) + '\n';
        _socket!.write(actionJson);
        print('Sent action: $actionJson');
      } catch (e, stackTrace) {
        _showErrorSnackBar('Error sending action: $e');
        print('Error sending action: $e\nStack trace: $stackTrace');
        _connectToServer();
      }
    } else if (mounted) {
      _showErrorSnackBar('No server connection');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });
    final scaffoldMessenger = ScaffoldMessenger.maybeOf(context);
    if (scaffoldMessenger != null) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
            message,
            style: GoogleFonts.orbitron(color: Colors.white70),
          ),
          backgroundColor: const Color(0xFFFF4500).withOpacity(0.8),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Colors.white70,
            onPressed: _connectToServer,
          ),
        ),
      );
    }
  }

  Widget _buildCell(int row, int col) {
    final value = _board[row][col];
    IconData? icon;
    String text = '';
    Color cellColor = const Color(0xFF1A1A3A).withOpacity(0.9);
    Color textColor = Colors.white70;
    double opacity = 0.9;

    if (value == 'hidden') {
      cellColor = const Color(0xFF1A1A3A);
    } else if (value == 'flag') {
      icon = Icons.flag;
      cellColor = const Color(0xFF00FFD1).withOpacity(0.3);
      opacity = 0.3;
    } else if (value == 'mine') {
      icon = Icons.warning_amber;
      cellColor = const Color(0xFFFF4500).withOpacity(0.8);
      opacity = 0.8;
    } else if (value is int) {
      text = value > 0 ? value.toString() : '';
      cellColor = const Color(0xFF0A0A1E).withOpacity(0.2);
      opacity = 0.2;
      textColor = [
        Colors.white,
        const Color(0xFF00FFD1),
        const Color(0xFF4B0082),
        const Color(0xFFFF4500),
        Colors.white70,
        const Color(0xFF00FFD1),
        const Color(0xFF4B0082),
        Colors.white,
        Colors.white54,
      ][value.clamp(0, 8)];
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
            filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cellColor, cellColor.withOpacity(opacity)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00FFD1).withOpacity(0.2),
                    blurRadius: 4,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Center(
                child: icon != null
                    ? Icon(icon, color: Colors.white70, size: 26)
                    : Text(
                        text,
                        style: GoogleFonts.orbitron(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
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
    Color bgColor = const Color(0xFF0A0A1E).withOpacity(0.3);

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
                  color: const Color(0xFF00FFD1).withOpacity(0.2),
                  blurRadius: 6,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Text(
              message,
              style: GoogleFonts.orbitron(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
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
    return BounceInDown(
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
                  color: const Color(0xFF0A0A1E).withOpacity(0.4),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Pulse(
                          duration: const Duration(milliseconds: 1000),
                          child: Text(
                            'GALACTIC VICTORY!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.orbitron(
                              fontSize: 44,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00FFD1),
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    _sendAction({'action': 'new_game'});
                                    if (mounted) {
                                      setState(() => _showWinOverlay = false);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                      0xFF00FFD1,
                                    ).withOpacity(0.3),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: const Color(
                                          0xFF00FFD1,
                                        ).withOpacity(0.5),
                                      ),
                                    ),
                                    elevation: 8,
                                  ),
                                  child: Text(
                                    'New Mission',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: ElevatedButton(
                                  onPressed: () => widget.onGameSelected(
                                    0,
                                  ), // Return to GamesScreen
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(
                                      0.2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    elevation: 8,
                                  ),
                                  child: Text(
                                    'Back to Games',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                icon: const Icon(Icons.close, color: Colors.white70, size: 32),
                onPressed: () {
                  if (mounted) {
                    setState(() => _showWinOverlay = false);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoseOverlay() {
    if (!_showLoseOverlay) return const SizedBox.shrink();
    return BounceInDown(
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
                  color: const Color(0xFF0A0A1E).withOpacity(0.4),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ShakeX(
                          duration: const Duration(milliseconds: 800),
                          child: Flash(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              'BLACK HOLE DEFEAT!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.orbitron(
                                fontSize: 44,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFF4500),
                                shadows: [
                                  Shadow(
                                    color: Colors.black.withOpacity(0.5),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    _sendAction({'action': 'new_game'});
                                    if (mounted) {
                                      setState(() => _showLoseOverlay = false);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                      0xFFFF4500,
                                    ).withOpacity(0.3),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: const Color(
                                          0xFFFF4500,
                                        ).withOpacity(0.5),
                                      ),
                                    ),
                                    elevation: 8,
                                  ),
                                  child: Text(
                                    'Retry Mission',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: ElevatedButton(
                                  onPressed: () => widget.onGameSelected(
                                    0,
                                  ), // Return to GamesScreen
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(
                                      0.2,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    elevation: 8,
                                  ),
                                  child: Text(
                                    'Back to Games',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                          ],
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
                icon: const Icon(Icons.close, color: Colors.white70, size: 32),
                onPressed: () {
                  if (mounted) {
                    setState(() => _showLoseOverlay = false);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorOverlay() {
    if (_errorMessage.isEmpty) return const SizedBox.shrink();
    return FadeIn(
      duration: const Duration(milliseconds: 500),
      child: Center(
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF0A0A1E).withOpacity(0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFF4500).withOpacity(0.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF4500).withOpacity(0.2),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorMessage,
                    style: GoogleFonts.orbitron(
                      color: const Color(0xFFFF4500),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ElevatedButton(
                            onPressed: _connectToServer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                0xFFFF4500,
                              ).withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: const Color(
                                    0xFFFF4500,
                                  ).withOpacity(0.5),
                                ),
                              ),
                            ),
                            child: Text(
                              'Retry Connection',
                              style: GoogleFonts.orbitron(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ElevatedButton(
                            onPressed: () => widget.onGameSelected(
                              0,
                            ), // Return to GamesScreen
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 16,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                                side: BorderSide(
                                  color: Colors.white.withOpacity(0.3),
                                ),
                              ),
                            ),
                            child: Text(
                              'Back to Games',
                              style: GoogleFonts.orbitron(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A1E), Color(0xFF1A1A3A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: StarField(opacity: 0.2)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white70,
                          size: 30,
                        ),
                        onPressed: () =>
                            widget.onGameSelected(0), // Return to GamesScreen
                      ),
                      Text(
                        'Galactic Minesweeper',
                        style: GoogleFonts.orbitron(
                          color: Colors.white70,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 30), // Placeholder for symmetry
                    ],
                  ),
                ),
                if (_isLoading || _board.isEmpty)
                  Expanded(
                    child: Center(
                      child: FadeIn(
                        duration: const Duration(milliseconds: 500),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(
                              color: Color(0xFF00FFD1),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Scanning cosmic mines...',
                              style: GoogleFonts.orbitron(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
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
                              color: Colors.white.withOpacity(0.2),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00FFD1,
                                  ).withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 2,
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FFD1).withOpacity(0.3),
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(
                          color: const Color(0xFF00FFD1).withOpacity(0.5),
                        ),
                      ),
                      elevation: 8,
                    ),
                    child: Text(
                      'New Mission',
                      style: GoogleFonts.orbitron(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildErrorOverlay(),
          _buildWinOverlay(),
          _buildLoseOverlay(),
        ],
      ),
    );
  }
}
