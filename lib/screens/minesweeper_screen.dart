import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brubaker_homeapp/screens/star_field.dart'; // Only StarField remains
import 'package:provider/provider.dart';
import 'package:brubaker_homeapp/theme.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:animate_do/animate_do.dart';
import 'dart:async';

class MinesweeperScreen extends StatefulWidget {
  final Function(int) onGameSelected;

  const MinesweeperScreen({super.key, required this.onGameSelected});

  @override
  MinesweeperScreenState createState() => MinesweeperScreenState();
}

class MinesweeperScreenState extends State<MinesweeperScreen> {
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
  int _retryAttempts = 0;
  static const int _maxRetries = 5;
  static const Duration _retryDelay = Duration(seconds: 2);
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _connectToServer();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _subscription?.cancel();
    _socket?.close();
    _socket = null;
    super.dispose();
  }

  Future<void> _connectToServer() async {
    if (_retryAttempts >= _maxRetries) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isConnected = false;
          _errorMessage =
              'Unable to connect after $_maxRetries attempts. Tap Retry to try again.';
        });
      }
      return;
    }

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
      ).timeout(const Duration(seconds: 20));
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isConnected = true;
          _retryAttempts = 0;
        });
      }
      _subscription = _socket!.listen(
        (List<int> data) {
          if (!mounted) return;
          _buffer += utf8.decode(data, allowMalformed: true);
          _debounceStateUpdate();
        },
        onError: (error) {
          _showErrorSnackBar('Connection error: $error');
          if (mounted) {
            setState(() {
              _isConnected = false;
              _board = _createFallbackBoard();
            });
          }
          _scheduleReconnect();
        },
        onDone: () {
          _showErrorSnackBar('Server connection closed');
          if (mounted) {
            setState(() {
              _isConnected = false;
              _board = _createFallbackBoard();
            });
          }
          _scheduleReconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      _showErrorSnackBar('Failed to connect to server: $e');
      if (mounted) {
        setState(() {
          _isConnected = false;
          _board = _createFallbackBoard();
        });
      }
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    _retryAttempts++;
    if (_retryAttempts < _maxRetries && mounted) {
      Future.delayed(_retryDelay, _connectToServer);
    }
  }

  void _debounceStateUpdate() {
    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      _processBuffer();
    });
  }

  void _processBuffer() {
    var lines = _buffer.split('\n');
    if (lines.length > 1) {
      for (int i = 0; i < lines.length - 1; i++) {
        var line = lines[i].trim();
        if (line.isEmpty) continue;
        try {
          final jsonData = jsonDecode(line);
          if (jsonData['type'] == 'state') {
            if (mounted) {
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
            }
          }
        } catch (e) {
          _showErrorSnackBar('Error parsing server data: $e');
        }
      }
      _buffer = lines.last;
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
        final actionJson = '${jsonEncode(action)}\n';
        _socket!.write(actionJson);
      } catch (e) {
        _showErrorSnackBar('Error sending action: $e');
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
            style: GoogleFonts.orbitron(
              color: Theme.of(context).textTheme.bodyLarge!.color,
            ),
          ),
          backgroundColor: Theme.of(
            context,
          ).colorScheme.secondary.withOpacity(0.8),
          action: SnackBarAction(
            label: 'Retry',
            textColor: Theme.of(context).textTheme.bodyLarge!.color,
            onPressed: _connectToServer,
          ),
        ),
      );
    }
  }

  // Galactic colors only
  Color _getCellColor(BuildContext context, dynamic value) {
    if (value == 'hidden') {
      return Theme.of(context).colorScheme.surface.withOpacity(0.9);
    } else if (value == 'flag') {
      return Theme.of(context).primaryColor.withOpacity(0.3);
    } else if (value == 'mine') {
      return Theme.of(context).colorScheme.secondary.withOpacity(0.8);
    } else {
      return Theme.of(context).scaffoldBackgroundColor.withOpacity(0.2);
    }
  }

  // Galactic number colors only
  Color _getTextColor(BuildContext context, dynamic value) {
    if (value is int && value > 0) {
      return [
        Colors.white,
        Theme.of(context).primaryColor,
        Colors.purple[700]!,
        Theme.of(context).colorScheme.secondary,
        Colors.white70,
        Theme.of(context).primaryColor,
        Colors.purple[700]!,
        Colors.white,
        Colors.white54,
      ][value.clamp(0, 8)];
    }
    return Theme.of(context).textTheme.bodyLarge!.color!;
  }

  Widget _buildCell(int row, int col) {
    final value = _board[row][col];
    IconData? icon;
    String text = '';
    Color cellColor = _getCellColor(context, value);
    Color textColor = _getTextColor(context, value);
    double opacity = value is int ? 0.2 : 0.9;

    if (value == 'flag') {
      icon = Icons.flag;
    } else if (value == 'mine') {
      icon = Icons.warning_amber;
    } else if (value is int) {
      text = value > 0 ? value.toString() : '';
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
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [cellColor, cellColor.withOpacity(opacity * 0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).textTheme.bodyLarge!.color!.withOpacity(0.4),
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 6,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Center(
                child: icon != null
                    ? Flash(
                        duration: const Duration(milliseconds: 200),
                        child: Icon(icon, color: textColor, size: 28),
                      )
                    : Text(
                        text,
                        style: GoogleFonts.orbitron(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
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
    Color bgColor = Theme.of(context).scaffoldBackgroundColor.withOpacity(0.3);

    return FadeIn(
      duration: const Duration(milliseconds: 500),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bgColor, bgColor.withOpacity(0.2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Theme.of(
                  context,
                ).textTheme.bodyLarge!.color!.withOpacity(0.4),
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.3),
                  blurRadius: 8,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Text(
              message,
              style: GoogleFonts.orbitron(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge!.color,
                shadows: [
                  Shadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
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
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withOpacity(0.5),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Pulse(
                          duration: const Duration(milliseconds: 1200),
                          child: Text(
                            'GALACTIC VICTORY!',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.orbitron(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                              shadows: [
                                Shadow(
                                  color: Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor.withOpacity(0.6),
                                  blurRadius: 12,
                                  offset: const Offset(0, 8),
                                ),
                                Shadow(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.5),
                                  blurRadius: 10,
                                  offset: const Offset(0, -2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    _sendAction({'action': 'new_game'});
                                    if (mounted) {
                                      setState(() => _showWinOverlay = false);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.5),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: BorderSide(
                                        color: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.7),
                                      ),
                                    ),
                                    elevation: 12,
                                  ),
                                  child: Text(
                                    'New Mission',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge!.color,
                                      shadows: [
                                        Shadow(
                                          color: Theme.of(
                                            context,
                                          ).primaryColor.withOpacity(0.6),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: ElevatedButton(
                                  onPressed: () => widget.onGameSelected(0),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surface.withOpacity(0.3),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: BorderSide(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color!
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                    elevation: 12,
                                  ),
                                  child: Text(
                                    'Back to Games',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge!.color,
                                      shadows: [
                                        Shadow(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .color!
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
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
              top: 50,
              right: 20,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  size: 36,
                ),
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
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Container(
                  color: Theme.of(
                    context,
                  ).scaffoldBackgroundColor.withOpacity(0.5),
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
                                fontSize: 48,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.secondary,
                                shadows: [
                                  Shadow(
                                    color: Theme.of(
                                      context,
                                    ).scaffoldBackgroundColor.withOpacity(0.6),
                                    blurRadius: 12,
                                    offset: const Offset(0, 8),
                                  ),
                                  Shadow(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary.withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: const Offset(0, -2),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: ElevatedButton(
                                  onPressed: () {
                                    _sendAction({'action': 'new_game'});
                                    if (mounted) {
                                      setState(() => _showLoseOverlay = false);
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.secondary.withOpacity(0.5),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: BorderSide(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .secondary
                                            .withOpacity(0.7),
                                      ),
                                    ),
                                    elevation: 12,
                                  ),
                                  child: Text(
                                    'Retry Mission',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge!.color,
                                      shadows: [
                                        Shadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .secondary
                                              .withOpacity(0.6),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                child: ElevatedButton(
                                  onPressed: () => widget.onGameSelected(0),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Theme.of(
                                      context,
                                    ).colorScheme.surface.withOpacity(0.3),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                      horizontal: 24,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      side: BorderSide(
                                        color: Theme.of(context)
                                            .textTheme
                                            .bodyLarge!
                                            .color!
                                            .withOpacity(0.5),
                                      ),
                                    ),
                                    elevation: 12,
                                  ),
                                  child: Text(
                                    'Back to Games',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge!.color,
                                      shadows: [
                                        Shadow(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .color!
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
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
              top: 50,
              right: 20,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: Theme.of(context).textTheme.bodyLarge!.color,
                  size: 36,
                ),
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
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary.withOpacity(0.3),
                    blurRadius: 8,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _errorMessage,
                    style: GoogleFonts.orbitron(
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      shadows: [
                        Shadow(
                          color: Theme.of(
                            context,
                          ).scaffoldBackgroundColor.withOpacity(0.4),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: ElevatedButton(
                            onPressed: _connectToServer,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.secondary.withOpacity(0.4),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary.withOpacity(0.6),
                                ),
                              ),
                            ),
                            child: Text(
                              'Retry Connection',
                              style: GoogleFonts.orbitron(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge!.color,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary.withOpacity(0.5),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
                            onPressed: () => widget.onGameSelected(0),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Theme.of(
                                context,
                              ).colorScheme.surface.withOpacity(0.3),
                              padding: const EdgeInsets.symmetric(
                                vertical: 14,
                                horizontal: 20,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyLarge!
                                      .color!
                                      .withOpacity(0.5),
                                ),
                              ),
                            ),
                            child: Text(
                              'Back to Games',
                              style: GoogleFonts.orbitron(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge!.color,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                shadows: [
                                  Shadow(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyLarge!
                                        .color!
                                        .withOpacity(0.4),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
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
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
            Theme.of(context).colorScheme.surface.withOpacity(0.6),
          ],
        ),
      ),
      child: Stack(
        children: [
          const Positioned.fill(
            child: StarField(opacity: 0.3), // Always galactic background
          ),
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
                        icon: Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                          size: 30,
                        ),
                        onPressed: () => widget.onGameSelected(0),
                      ),
                      Expanded(
                        child: Text(
                          'Galactic Minesweeper',
                          style: GoogleFonts.orbitron(
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.4),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 30),
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
                            CircularProgressIndicator(
                              color: Theme.of(context).primaryColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Scanning cosmic mines...',
                              style: GoogleFonts.orbitron(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge!.color,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                shadows: [
                                  Shadow(
                                    color: Theme.of(
                                      context,
                                    ).primaryColor.withOpacity(0.3),
                                    blurRadius: 6,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
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
                          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Theme.of(
                                    context,
                                  ).scaffoldBackgroundColor.withOpacity(0.3),
                                  Theme.of(
                                    context,
                                  ).colorScheme.surface.withOpacity(0.2),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).textTheme.bodyLarge!.color!.withOpacity(0.4),
                                width: 2,
                              ),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 3,
                                ),
                              ],
                            ),
                            child: GridView.builder(
                              padding: const EdgeInsets.all(6),
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
                      backgroundColor: Theme.of(
                        context,
                      ).primaryColor.withOpacity(0.4),
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 24,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(
                            context,
                          ).primaryColor.withOpacity(0.6),
                        ),
                      ),
                      elevation: 10,
                    ),
                    child: Text(
                      'New Mission',
                      style: GoogleFonts.orbitron(
                        color: Theme.of(context).textTheme.bodyLarge!.color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.5),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
