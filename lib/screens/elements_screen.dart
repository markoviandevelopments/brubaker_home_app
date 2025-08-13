import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import 'dart:ui'; // For BackdropFilter
import 'dart:math' as math; // For animations

const int GRID_W = 30;

class ElementsScreen extends StatefulWidget {
  const ElementsScreen({super.key});

  @override
  _ElementsScreenState createState() => _ElementsScreenState();
}

class _ElementsScreenState extends State<ElementsScreen>
    with SingleTickerProviderStateMixin {
  Socket? _socket;
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
  String _buffer = '';
  String _selectedElement = 'sand';
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  DateTime _lastUpdate = DateTime.now(); // Track last update to throttle

  final List<String> elements = [
    "nothing",
    "sand",
    "water",
    "stone",
    "cloud",
    "gas",
    "void",
    "clone",
    "fire",
    "soil",
    "plant",
    "birthday_cake",
    "candle",
  ];

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
  }

  @override
  void dispose() {
    _glowController.dispose();
    _disconnect();
    super.dispose();
  }

  Future<void> _connectToServer() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });
    try {
      _socket = await Socket.connect(
        '108.254.1.184',
        6001,
      ).timeout(const Duration(seconds: 5));
      _socket!.listen(
        (List<int> data) {
          _buffer += utf8.decode(data, allowMalformed: true);
          var lines = _buffer.split('\n');
          for (int i = 0; i < lines.length - 1; i++) {
            var line = lines[i].trim();
            if (line.isEmpty) continue;
            try {
              final jsonData = jsonDecode(line);
              if (jsonData['type'] == 'state') {
                if (DateTime.now().difference(_lastUpdate).inMilliseconds <
                    100) {
                  continue;
                }
                setState(() {
                  _lastUpdate = DateTime.now();
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
                    _grid = newGrid;
                    for (int y = 0; y < GRID_W; y++) {
                      for (int x = 0; x < GRID_W; x++) {
                        if (_grid[y][x] == 'candle') {
                          _candleLit[y][x] = math.Random().nextDouble() < 0.1;
                        } else {
                          _candleLit[y][x] = false;
                        }
                      }
                    }
                  } else {
                    _errorMessage = 'Received invalid grid size';
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
            _isLoading = false;
          });
          _disconnect();
        },
        onDone: () {
          setState(() {
            _errorMessage = 'Socket connection closed';
            _isLoading = false;
          });
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
        _grid = List.generate(
          GRID_W,
          (_) => List.generate(GRID_W, (_) => 'nothing'),
        );
        _candleLit = List.generate(
          GRID_W,
          (_) => List.generate(GRID_W, (_) => false),
        );
        _isLoading = false;
      });
    }
  }

  void _sendAction(Map<String, dynamic> action) {
    if (_socket != null && action['element'] != null) {
      try {
        _socket!.write(jsonEncode(action) + '\n');
      } catch (e) {
        setState(() {
          _errorMessage = 'Error sending action: $e';
        });
      }
    }
  }

  Widget _buildCell(int row, int col) {
    final value = _grid[row][col];
    Widget cellContent;
    BoxDecoration? decoration;

    switch (value) {
      case 'sand':
        decoration = BoxDecoration(
          color: const Color(0xFFFFEFCE),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFFFEFCE,
              ).withOpacity(0.3 * _glowAnimation.value),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Container();
        break;
      case 'water':
        decoration = BoxDecoration(
          gradient: RadialGradient(
            colors: [
              const Color(0xFF3B87D3).withOpacity(0.8),
              const Color(0xFF1A4A8A),
            ],
            radius: 0.7,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF00FFFF,
              ).withOpacity(0.4 * _glowAnimation.value),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Container();
        break;
      case 'stone':
        decoration = BoxDecoration(
          color: const Color(0xFF646464),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFF646464,
              ).withOpacity(0.3 * _glowAnimation.value),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Container();
        break;
      case 'cloud':
        decoration = BoxDecoration(
          color: const Color(0xFFADD8E6).withOpacity(0.7),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFADD8E6,
              ).withOpacity(0.3 * _glowAnimation.value),
              blurRadius: 6,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Container();
        break;
      case 'gas':
        decoration = BoxDecoration(
          gradient: LinearGradient(
            colors: [const Color(0xFFF50B94), const Color(0xFF8B008B)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFFF00FF,
              ).withOpacity(0.4 * _glowAnimation.value),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Container();
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
                0xFFFFFF00,
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
        cellContent = Container();
        break;
      case 'soil':
        decoration = BoxDecoration(
          color: const Color(0xFFAF724E),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFAF724E,
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
                0xFF6B8E23,
              ).withOpacity(0.4 * _glowAnimation.value),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        );
        cellContent = Container();
        break;
      case 'birthday_cake':
        decoration = BoxDecoration(
          color: const Color(0xFFD2B48C),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0xFFFF69B4,
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
          color: const Color(0xFF00AAE4),
          boxShadow: [
            BoxShadow(
              color: _candleLit[row][col]
                  ? const Color(
                      0xFFFF8C00,
                    ).withOpacity(0.5 * _glowAnimation.value)
                  : const Color(
                      0xFF00AAE4,
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
                width: 4,
                height: 12,
                color: const Color(0xFF00AAE4),
              ),
            ),
            if (_candleLit[row][col])
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 4,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF8C00),
                    shape: BoxShape.circle,
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
        return Container(decoration: decoration, child: cellContent);
      },
    );
  }

  void _handlePointerEvent(PointerEvent event) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Galactic Elements',
          style: TextStyle(
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF00FFFF), // Neon cyan
          ),
        ),
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
          child: Column(
            children: [
              if (_errorMessage.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    _errorMessage,
                    style: const TextStyle(
                      color: Color(0xFFFF0088), // Neon pink error
                      fontFamily: 'Courier',
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                        ),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedElement,
                        items: elements.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value.replaceAll('_', ' ').toUpperCase(),
                              style: const TextStyle(
                                fontFamily: 'Courier',
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF00FFFF), // Neon cyan
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedElement = newValue!;
                          });
                        },
                        style: const TextStyle(
                          color: Color(0xFF00FFFF),
                          fontSize: 16,
                        ),
                        dropdownColor: const Color(0xFF0A0A1E).withOpacity(0.8),
                        underline: Container(
                          height: 2,
                          color: const Color(0xFFFF00FF), // Neon magenta
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (_isLoading)
                const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00FFFF)),
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
      ),
    );
  }
}
