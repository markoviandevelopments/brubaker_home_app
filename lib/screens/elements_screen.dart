import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/scheduler.dart';
import 'package:brubaker_homeapp/screens/star_field.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'package:animate_do/animate_do.dart';

const int GRID_W = 30;

class ElementsScreen extends StatefulWidget {
  final Function(int) onGameSelected; // Required for navigation

  const ElementsScreen({super.key, required this.onGameSelected});

  @override
  _ElementsScreenState createState() => _ElementsScreenState();
}

class _ElementsScreenState extends State<ElementsScreen>
    with SingleTickerProviderStateMixin {
  Socket? _socket;
  StreamSubscription<List<int>>? _subscription;
  List<List<String>> _grid = List.generate(
    GRID_W,
    (_) => List.generate(GRID_W, (_) => 'nothing'),
  );
  List<List<bool>> _candleLit = List.generate(
    GRID_W,
    (_) => List.generate(GRID_W, (_) => false),
  );
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isConnected = false;
  String _buffer = '';
  String _selectedElement = 'sand';
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  DateTime _lastUpdate = DateTime.now();
  int _retryAttempts = 0;
  static const int _maxRetries = 20;
  Timer? _debounceTimer;
  final Map<String, List<Offset>> _particleCache = {};
  final Map<String, IconData> _elementIcons = {
    'nothing': Icons.clear,
    'sand': Icons.grain,
    'water': Icons.water_drop,
    'stone': Icons.brightness_4,
    'cloud': Icons.cloud,
    'gas': Icons.air,
    'void': Icons.dark_mode,
    'clone': Icons.copy,
    'fire': Icons.local_fire_department,
    'soil': Icons.terrain,
    'plant': Icons.local_florist,
    'birthday_cake': Icons.cake,
    'candle': Icons.light,
  };

  final List<String> elements = [
    'nothing',
    'sand',
    'water',
    'stone',
    'cloud',
    'gas',
    'void',
    'clone',
    'fire',
    'soil',
    'plant',
    'birthday_cake',
    'candle',
  ];

  final List<Map<String, dynamic>> _serverEndpoints = [
    {'ip': '127.0.0.1', 'port': 6001},
    {'ip': '108.254.1.184', 'port': 6001},
  ];
  int _currentEndpointIndex = 0;

  final GlobalKey _gridKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _connectToServer();
    _initializeParticleCache();
  }

  void _initializeParticleCache() {
    for (var element in ['sand', 'stone', 'gas', 'cloud']) {
      _particleCache[element] = List.generate(
        5,
        (_) => Offset(
          math.Random().nextDouble() * 10,
          math.Random().nextDouble() * 10,
        ),
      );
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _glowController.dispose();
    _disconnect();
    super.dispose();
  }

  Future<void> _connectToServer() async {
    if (_retryAttempts >= _maxRetries) {
      if (mounted) {
        setState(() {
          _errorMessage =
              'Max retry attempts reached for ${_serverEndpoints[_currentEndpointIndex]['ip']}:${_serverEndpoints[_currentEndpointIndex]['port']}. Using fallback grid.';
          _isLoading = false;
          _isConnected = false;
          _grid = _createFallbackGrid();
        });
      }
      _currentEndpointIndex =
          (_currentEndpointIndex + 1) % _serverEndpoints.length;
      _retryAttempts = 0;
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _connectToServer();
      }
      return;
    }
    await _disconnect();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    await Future.delayed(const Duration(milliseconds: 200));
    try {
      final endpoint = _serverEndpoints[_currentEndpointIndex];
      _socket = await Socket.connect(
        endpoint['ip'],
        endpoint['port'],
      ).timeout(const Duration(seconds: 15));
      if (mounted) {
        setState(() {
          _isConnected = true;
          _isLoading = false;
        });
      }
      _subscription = _socket!.listen(
        (List<int> data) {
          if (!mounted) return;
          _buffer += utf8.decode(data, allowMalformed: true);
          var lines = _buffer.split('\n');
          for (int i = 0; i < lines.length - 1; i++) {
            var line = lines[i].trim();
            if (line.isEmpty) continue;
            try {
              final jsonData = jsonDecode(line);
              if (jsonData['type'] == 'state' && mounted) {
                if (DateTime.now().difference(_lastUpdate).inMilliseconds <
                    100) {
                  continue;
                }
                setState(() {
                  _lastUpdate = DateTime.now();
                  _retryAttempts = 0;
                  final newGrid = (jsonData['grid'] as List)
                      .map(
                        (row) => (row as List)
                            .map(
                              (cell) => elements.contains(cell)
                                  ? cell as String
                                  : 'nothing',
                            )
                            .toList(),
                      )
                      .toList();
                  if (newGrid.length == GRID_W &&
                      newGrid.every((row) => row.length == GRID_W)) {
                    for (int y = 0; y < GRID_W; y++) {
                      for (int x = 0; x < GRID_W; x++) {
                        if (newGrid[y][x] == 'candle') {
                          _candleLit[y][x] = math.Random().nextDouble() < 0.1;
                        } else {
                          _candleLit[y][x] = false;
                        }
                      }
                    }
                    _grid = newGrid;
                  } else {
                    _errorMessage = 'Received invalid grid size';
                  }
                });
              }
            } catch (e) {
              if (mounted) {
                setState(() {
                  _errorMessage = 'Error parsing data: $e';
                });
              }
            }
          }
          _buffer = lines.last;
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Connection error: $error';
              _isConnected = false;
              _isLoading = false;
            });
          }
          _retryAttempts++;
          _connectToServer();
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _errorMessage = 'Server connection closed';
              _isConnected = false;
              _isLoading = false;
            });
          }
          _retryAttempts++;
          _connectToServer();
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to connect to server: $e';
          _isConnected = false;
          _isLoading = false;
        });
      }
      _retryAttempts++;
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

  List<List<String>> _createFallbackGrid() {
    final grid = List.generate(
      GRID_W,
      (_) => List.generate(GRID_W, (_) => 'nothing'),
    );
    for (int y = 10; y < 20; y++) {
      for (int x = 10; x < 20; x++) {
        grid[y][x] = elements[math.Random().nextInt(elements.length)];
        if (grid[y][x] == 'candle') {
          _candleLit[y][x] = math.Random().nextBool();
        }
      }
    }
    return grid;
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
            onPressed: () {
              if (mounted) {
                setState(() => _retryAttempts = 0);
                _connectToServer();
              }
            },
          ),
        ),
      );
    }
  }

  void _sendAction(Map<String, dynamic> action) {
    if (_socket != null && action['element'] != null && _isConnected) {
      try {
        final actionJson = jsonEncode(action) + '\n';
        _socket!.write(actionJson);
        _showPlacementFeedback(action['x'], action['y']);
      } catch (e) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Error sending action: $e';
          });
        }
      }
    } else if (mounted) {
      setState(() {
        _errorMessage = 'Not connected to server. Using local grid.';
      });
    }
  }

  void _showPlacementFeedback(int x, int y) {
    // Visual feedback can be added here if desired
  }

  bool _isWaterAdjacent(int row, int col, String direction) {
    switch (direction) {
      case 'up':
        return row > 0 && _grid[row - 1][col] == 'water';
      case 'down':
        return row < GRID_W - 1 && _grid[row + 1][col] == 'water';
      case 'left':
        return col > 0 && _grid[row][col - 1] == 'water';
      case 'right':
        return col < GRID_W - 1 && _grid[row][col + 1] == 'water';
      default:
        return false;
    }
  }

  Widget _buildCell(int row, int col) {
    final value = _grid[row][col];
    Widget cellContent = Container();
    BoxDecoration? decoration;

    switch (value) {
      case 'sand':
        decoration = BoxDecoration(
          color: const Color(0xFFFFEFCE),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF00FFD1,
              ).withOpacity(0.3 * _glowAnimation.value),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Stack(
          children: _particleCache['sand']!.map((offset) {
            return Positioned(
              left: offset.dx,
              top: offset.dy,
              child: Container(
                width: 1,
                height: 1,
                color: const Color(0xFFD2B48C).withOpacity(0.5),
              ),
            );
          }).toList(),
        );
        break;
      case 'water':
        List<Color> waterColors = [
          const Color(0xFF00FFD1).withOpacity(0.8),
          const Color(0xFF1A4A8A),
        ];
        Gradient gradient;
        if (_isWaterAdjacent(row, col, 'left') &&
            _isWaterAdjacent(row, col, 'right')) {
          gradient = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: waterColors,
          );
        } else if (_isWaterAdjacent(row, col, 'up') &&
            _isWaterAdjacent(row, col, 'down')) {
          gradient = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: waterColors,
          );
        } else {
          gradient = RadialGradient(colors: waterColors, radius: 0.7);
        }
        decoration = BoxDecoration(
          gradient: gradient,
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF00FFD1,
              ).withOpacity(0.4 * _glowAnimation.value),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2 * _glowAnimation.value),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        );
        break;
      case 'stone':
        decoration = BoxDecoration(
          color: const Color(0xFF646464),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 4,
              spreadRadius: 1,
              offset: const Offset(2, 2),
            ),
            BoxShadow(
              color: const Color(
                0xFF00FFD1,
              ).withOpacity(0.2 * _glowAnimation.value),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Stack(
          children: _particleCache['stone']!.map((offset) {
            return Positioned(
              left: offset.dx,
              top: offset.dy,
              child: Container(
                width: 2,
                height: 2,
                color: math.Random().nextBool()
                    ? const Color(0xFF4A4A4A)
                    : const Color(0xFF808080),
              ),
            );
          }).toList(),
        );
        break;
      case 'cloud':
        decoration = BoxDecoration(
          gradient: RadialGradient(
            colors: [
              const Color(0xFFADD8E6).withOpacity(0.7 * _glowAnimation.value),
              Colors.white.withOpacity(0.5 * _glowAnimation.value),
            ],
            radius: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF00FFD1,
              ).withOpacity(0.3 * _glowAnimation.value),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Stack(
          children: [
            Positioned(
              left: 2,
              top: 2,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              right: 2,
              bottom: 2,
              child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        );
        break;
      case 'gas':
        decoration = BoxDecoration(
          gradient: RadialGradient(
            colors: [
              const Color(0xFFF50B94).withOpacity(0.8),
              const Color(0xFF8B008B),
            ],
            radius: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF00FFD1,
              ).withOpacity(0.4 * _glowAnimation.value),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Stack(
          children: _particleCache['gas']!.map((offset) {
            return Positioned(
              left: offset.dx,
              top: offset.dy,
              child: Container(
                width: 1,
                height: 1,
                color: Colors.white.withOpacity(0.6 * _glowAnimation.value),
              ),
            );
          }).toList(),
        );
        break;
      case 'void':
        decoration = BoxDecoration(
          color: const Color(0xFF1E0000),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Container();
        break;
      case 'clone':
        decoration = BoxDecoration(
          color: const Color(0xFFFFFF00),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF00FFD1,
              ).withOpacity(0.4 * _glowAnimation.value),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Container();
        break;
      case 'fire':
        decoration = BoxDecoration(
          gradient: RadialGradient(
            colors: [const Color(0xFFFF4500), const Color(0xFF8B0000)],
            radius: 0.6,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFFF4500,
              ).withOpacity(0.5 * _glowAnimation.value),
              blurRadius: 10,
              spreadRadius: 3,
            ),
          ],
        );
        cellContent = Stack(
          children: [
            Align(
              alignment: Alignment.bottomCenter,
              child: ClipPath(
                clipper: FlameClipper(),
                child: Container(
                  color: const Color(0xFFFFD700).withOpacity(0.6),
                  height: 12,
                  width: 8,
                ),
              ),
            ),
          ],
        );
        break;
      case 'soil':
        decoration = BoxDecoration(
          color: const Color(0xFFAF724E),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF00FFD1,
              ).withOpacity(0.3 * _glowAnimation.value),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Container();
        break;
      case 'plant':
        decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFF6B8E23), const Color(0xFF3C5F15)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF00FFD1,
              ).withOpacity(0.4 * _glowAnimation.value),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Stack(
          children: [
            Center(
              child: Container(
                width: 4,
                height: 12,
                color: const Color(0xFF228B22),
              ),
            ),
            Positioned(
              left: 2,
              top: 4,
              child: Container(
                width: 6,
                height: 4,
                color: const Color(0xFF32CD32),
              ),
            ),
          ],
        );
        break;
      case 'birthday_cake':
        decoration = BoxDecoration(
          color: const Color(0xFFD2B48C),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF00FFD1,
              ).withOpacity(0.4 * _glowAnimation.value),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Stack(
          children: [
            Container(color: const Color(0xFFD2B48C)),
            Align(
              alignment: Alignment.topCenter,
              child: Container(height: 8, color: const Color(0xFFFD6C99)),
            ),
          ],
        );
        break;
      case 'candle':
        decoration = BoxDecoration(
          color: Colors.transparent,
          boxShadow: [
            BoxShadow(
              color: _candleLit[row][col]
                  ? const Color(
                      0xFFFF4500,
                    ).withOpacity(0.5 * _glowAnimation.value)
                  : const Color(
                      0xFF00FFD1,
                    ).withOpacity(0.3 * _glowAnimation.value),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Stack(
          children: [
            Center(
              child: Container(
                width: 2,
                height: 12,
                color: const Color(0xFF00AAE4),
              ),
            ),
            if (_candleLit[row][col])
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 2,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF4500),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withOpacity(0.6),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
        break;
      default:
        decoration = const BoxDecoration(color: Color(0xFF0A0A1E));
        cellContent = Container();
        break;
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return RepaintBoundary(
          child: Container(decoration: decoration, child: cellContent),
        );
      },
    );
  }

  void _handlePointerEvent(PointerEvent event) {
    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final RenderBox? box =
          _gridKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final Offset localPosition = box.globalToLocal(event.position);
      final int row = (localPosition.dy / (box.size.height / GRID_W)).floor();
      final int col = (localPosition.dx / (box.size.width / GRID_W)).floor();

      if (row >= 0 && row < GRID_W && col >= 0 && col < GRID_W) {
        _sendAction({
          'action': 'place',
          'x': col,
          'y': row,
          'element': _selectedElement,
        });
      }
    });
  }

  Widget _buildElementSelector() {
    return Container(
      height: 80,
      margin: const EdgeInsets.all(8.0),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: elements.length,
        itemBuilder: (context, index) {
          final element = elements[index];
          final isSelected = element == _selectedElement;
          return GestureDetector(
            onTap: () {
              if (mounted) {
                setState(() {
                  _selectedElement = element;
                });
              }
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 4.0),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF00FFD1).withOpacity(0.8)
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF00FFD1).withOpacity(0.7)
                      : Colors.white.withOpacity(0.3),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(
                      0xFF00FFD1,
                    ).withOpacity(0.2 * _glowAnimation.value),
                    blurRadius: 6,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_elementIcons[element], color: Colors.white70, size: 24),
                  const SizedBox(height: 4),
                  Text(
                    element.replaceAll('_', ' ').toUpperCase(),
                    style: GoogleFonts.orbitron(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
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
                      ElevatedButton(
                        onPressed: () {
                          if (mounted) {
                            setState(() => _retryAttempts = 0);
                            _connectToServer();
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFFFF4500,
                          ).withOpacity(0.3),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: const Color(0xFFFF4500).withOpacity(0.5),
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
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () => widget.onGameSelected(0),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
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
                        onPressed: () => widget.onGameSelected(0),
                      ),
                      Text(
                        'Galactic Elements',
                        style: GoogleFonts.orbitron(
                          color: Colors.white70,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          _isConnected ? Icons.link : Icons.link_off,
                          color: _isConnected
                              ? const Color(0xFF00FFD1)
                              : const Color(0xFFFF4500),
                          size: 30,
                        ),
                        onPressed: () {
                          if (mounted) {
                            setState(() => _retryAttempts = 0);
                            _connectToServer();
                          }
                        },
                      ),
                    ],
                  ),
                ),
                _buildElementSelector(),
                if (_isLoading)
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
                              'Connecting to server...',
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
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final double size =
                            constraints.maxWidth < constraints.maxHeight
                            ? constraints.maxWidth
                            : constraints.maxHeight;
                        return Center(
                          child: SizedBox(
                            width: size,
                            height: size,
                            child: Listener(
                              key: _gridKey,
                              onPointerDown: _handlePointerEvent,
                              onPointerMove: _handlePointerEvent,
                              child: GridView.builder(
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: GRID_W,
                                      childAspectRatio: 1,
                                    ),
                                itemCount: GRID_W * GRID_W,
                                itemBuilder: (context, index) {
                                  final row = index ~/ GRID_W;
                                  final col = index % GRID_W;
                                  return _buildCell(row, col);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          _buildErrorOverlay(),
        ],
      ),
    );
  }
}

class FlameClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width / 2, 0);
    path.quadraticBezierTo(
      size.width,
      size.height / 2,
      size.width / 2,
      size.height,
    );
    path.quadraticBezierTo(0, size.height / 2, size.width / 2, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
