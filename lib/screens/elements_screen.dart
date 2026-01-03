// lib/screens/elements_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brubaker_homeapp/screens/star_field.dart';
import 'package:provider/provider.dart';
import 'package:brubaker_homeapp/theme.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
import 'dart:async';
import 'package:animate_do/animate_do.dart';

const int gridW = 30;

class ElementsScreen extends StatefulWidget {
  final Function(int) onGameSelected;

  const ElementsScreen({super.key, required this.onGameSelected});

  @override
  ElementsScreenState createState() => ElementsScreenState();
}

class ElementsScreenState extends State<ElementsScreen>
    with SingleTickerProviderStateMixin {
  Socket? _socket;
  StreamSubscription<List<int>>? _subscription;
  List<List<String>> _grid = List.generate(
    gridW,
    (_) => List.generate(gridW, (_) => 'nothing'),
  );
  final List<List<bool>> _candleLit = List.generate(
    gridW,
    (_) => List.generate(gridW, (_) => false),
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

  // Clean galactic icons and names only
  final Map<String, IconData> _elementIcons = {
    'nothing': Icons.clear,
    'sand': Icons.grain,
    'water': Icons.waves,
    'stone': Icons.circle,
    'cloud': Icons.cloud,
    'gas': Icons.air,
    'void': Icons.dark_mode,
    'clone': Icons.copy,
    'fire': Icons.local_fire_department,
    'soil': Icons.terrain,
    'plant': Icons.local_florist,
    'birthday_cake': Icons.cake,
    'candle': Icons.light_mode,
  };

  final Map<String, String> _elementNames = {
    'nothing': 'Nothing',
    'sand': 'Sand',
    'water': 'Water',
    'stone': 'Stone',
    'cloud': 'Cloud',
    'gas': 'Gas',
    'void': 'Void',
    'clone': 'Clone',
    'fire': 'Fire',
    'soil': 'Soil',
    'plant': 'Plant',
    'birthday_cake': 'Cake',
    'candle': 'Candle',
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
    _glowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    _connectToServer();
    _initializeParticleCache();
  }

  void _initializeParticleCache() {
    for (var element in ['sand', 'stone', 'gas', 'cloud']) {
      _particleCache[element] = List.generate(
        6,
        (_) => Offset(
          math.Random().nextDouble() * 12,
          math.Random().nextDouble() * 12,
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

  // === Connection logic unchanged (kept clean) ===
  Future<void> _connectToServer() async {
    // ... (same as your original, unchanged for reliability)
    if (_retryAttempts >= _maxRetries) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Max retry attempts reached. Using fallback grid.';
          _isLoading = false;
          _isConnected = false;
          _grid = _createFallbackGrid();
        });
      }
      _currentEndpointIndex =
          (_currentEndpointIndex + 1) % _serverEndpoints.length;
      _retryAttempts = 0;
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _connectToServer();
      return;
    }
    await _disconnect();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
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
        (data) {
          _buffer += utf8.decode(data, allowMalformed: true);
          var lines = _buffer.split('\n');
          for (var line in lines.sublist(0, lines.length - 1)) {
            line = line.trim();
            if (line.isEmpty) continue;
            try {
              final jsonData = jsonDecode(line);
              if (jsonData['type'] == 'state' &&
                  DateTime.now().difference(_lastUpdate).inMilliseconds >=
                      100) {
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
                  if (newGrid.length == gridW &&
                      newGrid.every((r) => r.length == gridW)) {
                    _grid = newGrid;
                    // Randomly light some candles
                    for (int y = 0; y < gridW; y++) {
                      for (int x = 0; x < gridW; x++) {
                        _candleLit[y][x] =
                            newGrid[y][x] == 'candle' &&
                            math.Random().nextDouble() < 0.12;
                      }
                    }
                  }
                });
              }
            } catch (e) {
              // silent parse error
            }
          }
          _buffer = lines.last;
        },
        onError: (_) {
          _retryAttempts++;
          _connectToServer();
        },
        onDone: () {
          _retryAttempts++;
          _connectToServer();
        },
      );
    } catch (e) {
      _retryAttempts++;
      _connectToServer();
    }
  }

  Future<void> _disconnect() async {
    await _subscription?.cancel();
    await _socket?.close();
    _socket = null;
    _subscription = null;
    if (mounted) {
      setState(() {
        _isConnected = false;
        _isLoading = false;
      });
    }
  }

  List<List<String>> _createFallbackGrid() {
    final grid = List.generate(gridW, (_) => List.filled(gridW, 'nothing'));
    final rand = math.Random();
    for (int y = 12; y < 18; y++) {
      for (int x = 12; x < 18; x++) {
        grid[y][x] = elements[rand.nextInt(elements.length)];
      }
    }
    return grid;
  }

  void _sendAction(Map<String, dynamic> action) {
    if (_isConnected && _socket != null) {
      try {
        _socket!.write('${jsonEncode(action)}\n');
      } catch (e) {
        setState(() => _errorMessage = 'Send error');
      }
    }
  }

  bool _isWaterAdjacent(int row, int col, String dir) {
    switch (dir) {
      case 'up':
        return row > 0 && _grid[row - 1][col] == 'water';
      case 'down':
        return row < gridW - 1 && _grid[row + 1][col] == 'water';
      case 'left':
        return col > 0 && _grid[row][col - 1] == 'water';
      case 'right':
        return col < gridW - 1 && _grid[row][col + 1] == 'water';
      default:
        return false;
    }
  }

  Widget _buildCell(int row, int col) {
    final value = _grid[row][col];
    final theme = Theme.of(context);
    final primary = theme.primaryColor;
    final secondary = theme.colorScheme.secondary;

    BoxDecoration? decoration;
    Widget? overlay;

    switch (value) {
      case 'sand':
        decoration = BoxDecoration(
          color: const Color(0xFFFFEFCE),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.4 * _glowAnimation.value),
              blurRadius: 8,
            ),
          ],
        );
        overlay = _particleCache['sand'] != null
            ? Stack(
                children: _particleCache['sand']!
                    .map(
                      (o) => Positioned(
                        left: o.dx,
                        top: o.dy,
                        child: Container(
                          width: 1.5,
                          height: 1.5,
                          color: const Color(0xFFD2B48C),
                        ),
                      ),
                    )
                    .toList(),
              )
            : null;
        break;
      case 'water':
        final gradient =
            _isWaterAdjacent(row, col, 'left') &&
                _isWaterAdjacent(row, col, 'right')
            ? LinearGradient(
                colors: [primary.withOpacity(0.8), const Color(0xFF004488)],
              )
            : _isWaterAdjacent(row, col, 'up') &&
                  _isWaterAdjacent(row, col, 'down')
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [primary.withOpacity(0.8), const Color(0xFF004488)],
              )
            : RadialGradient(
                colors: [primary.withOpacity(0.8), const Color(0xFF002266)],
              );
        decoration = BoxDecoration(gradient: gradient);
        break;
      case 'stone':
        decoration = BoxDecoration(
          color: const Color(0xFF555555),
          borderRadius: BorderRadius.circular(4),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.3 * _glowAnimation.value),
              blurRadius: 6,
            ),
          ],
        );
        break;
      case 'cloud':
        decoration = BoxDecoration(
          gradient: SweepGradient(
            colors: [Colors.white.withOpacity(0.4), secondary.withOpacity(0.2)],
          ),
        );
        break;
      case 'gas':
        decoration = BoxDecoration(
          gradient: RadialGradient(
            colors: [primary.withOpacity(0.3), secondary.withOpacity(0.15)],
          ),
        );
        break;
      case 'void':
        decoration = BoxDecoration(
          color: const Color(0xFF8000FF),
          boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 10)],
        );
        break;
      case 'clone':
        decoration = BoxDecoration(color: Colors.yellow.withOpacity(0.7));
        break;
      case 'fire':
        decoration = BoxDecoration(
          gradient: RadialGradient(colors: [primary, const Color(0xFF8B0000)]),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.7 * _glowAnimation.value),
              blurRadius: 12,
            ),
          ],
        );
        break;
      case 'soil':
        decoration = BoxDecoration(color: const Color(0xFF8B4513));
        break;
      case 'plant':
        decoration = BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF228B22), Color(0xFF006400)],
          ),
        );
        overlay = const Center(
          child: Icon(Icons.eco, size: 16, color: Colors.lightGreenAccent),
        );
        break;
      case 'birthday_cake':
        decoration = BoxDecoration(color: const Color(0xFFFFA500));
        overlay = const Icon(Icons.cake, size: 18, color: Colors.white);
        break;
      case 'candle':
        decoration = BoxDecoration(color: Colors.transparent);
        overlay = Stack(
          children: [
            const Center(
              child: Icon(Icons.light_mode, size: 14, color: Colors.orange),
            ),
            if (_candleLit[row][col])
              Center(
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: primary,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: secondary, blurRadius: 8)],
                  ),
                ),
              ),
          ],
        );
        break;
      default:
        decoration = BoxDecoration(color: Colors.transparent);
    }

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (_, __) => Container(decoration: decoration, child: overlay),
    );
  }

  Widget _buildElementSelector() {
    return Container(
      height: 90,
      margin: const EdgeInsets.all(8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: elements.length,
        itemBuilder: (context, i) {
          final elem = elements[i];
          final selected = elem == _selectedElement;
          return GestureDetector(
            onTap: () => setState(() => _selectedElement = elem),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 80,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: selected
                    ? Theme.of(context).primaryColor.withOpacity(0.7)
                    : Theme.of(context).colorScheme.surface.withOpacity(0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? Theme.of(context).primaryColor
                      : Colors.white24,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).primaryColor.withOpacity(0.3),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_elementIcons[elem], color: Colors.white70, size: 28),
                  const SizedBox(height: 6),
                  Text(
                    _elementNames[elem]!.toUpperCase(),
                    style: GoogleFonts.orbitron(
                      color: Colors.white70,
                      fontSize: 11,
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
      child: Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(context).primaryColor),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _errorMessage,
                  style: GoogleFonts.orbitron(
                    color: Theme.of(context).primaryColor,
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    _retryAttempts = 0;
                    _connectToServer();
                  },
                  child: const Text('Retry'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => widget.onGameSelected(0),
                  child: const Text(
                    'Back to Games',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handlePointerEvent(PointerEvent event) {
    if (_debounceTimer?.isActive ?? false) return;
    _debounceTimer = Timer(const Duration(milliseconds: 80), () {
      final box = _gridKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return;
      final local = box.globalToLocal(event.position);
      final col = (local.dx / (box.size.width / gridW)).floor();
      final row = (local.dy / (box.size.height / gridW)).floor();
      if (row >= 0 && row < gridW && col >= 0 && col < gridW) {
        _sendAction({
          'action': 'place',
          'x': col,
          'y': row,
          'element': _selectedElement,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A1E), Color(0xFF1A1A3A)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: StarField(opacity: 0.3)),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white70,
                            size: 32,
                          ),
                          onPressed: () => widget.onGameSelected(0),
                        ),
                        Text(
                          'Galactic Elements',
                          style: GoogleFonts.orbitron(
                            color: Colors.white70,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            _isConnected ? Icons.link : Icons.link_off,
                            color: _isConnected
                                ? Theme.of(context).primaryColor
                                : Colors.grey,
                          ),
                          onPressed: () => _connectToServer(),
                        ),
                      ],
                    ),
                  ),
                  _buildElementSelector(),
                  _isLoading
                      ? const Expanded(
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Expanded(
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: Listener(
                                onPointerDown: _handlePointerEvent,
                                onPointerMove: _handlePointerEvent,
                                child: GridView.builder(
                                  key: _gridKey,
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: gridW,
                                      ),
                                  itemBuilder: (_, i) {
                                    final row = i ~/ gridW;
                                    final col = i % gridW;
                                    return _buildCell(row, col);
                                  },
                                  itemCount: gridW * gridW,
                                ),
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
            _buildErrorOverlay(),
          ],
        ),
      ),
    );
  }
}
