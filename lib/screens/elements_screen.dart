import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

const int GRID_W = 30;

class ElementsScreen extends StatefulWidget {
  const ElementsScreen({super.key});

  @override
  _ElementsScreenState createState() => _ElementsScreenState();
}

class _ElementsScreenState extends State<ElementsScreen> {
  Socket? _socket;
  List<List<String>> _grid = List.generate(
    GRID_W,
    (_) => List.generate(GRID_W, (_) => 'nothing'),
  );
  String _errorMessage = '';
  bool _isLoading = false;
  String _buffer = '';
  String _selectedElement = 'sand';
  final List<String> elements = [
    "nothing",
    "sand",
    "water",
    "block",
    "cloud",
    "gas",
    "void",
    "clone",
  ];
  final GlobalKey _gridKey = GlobalKey();

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
      _socket = await Socket.connect('108.254.1.184', 6001);
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
                  _grid = (jsonData['grid'] as List)
                      .map(
                        (row) => (row as List)
                            .map((cell) => cell as String)
                            .toList(),
                      )
                      .toList();
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
        _grid = List.generate(
          GRID_W,
          (_) => List.generate(GRID_W, (_) => 'nothing'),
        );
      });
    }
  }

  void _sendAction(Map<String, dynamic> action) {
    if (_socket != null) {
      _socket!.write(jsonEncode(action) + '\n');
    }
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }

  Widget _buildCell(int row, int col) {
    final value = _grid[row][col];
    Color cellColor = const Color.fromARGB(
      255,
      48,
      48,
      48,
    ); // Nothing - clean, neutral base

    if (value == 'sand') {
      cellColor = const Color.fromARGB(255, 255, 239, 206); // Sand
    } else if (value == 'water') {
      cellColor = const Color.fromARGB(255, 59, 135, 211); // Water
    } else if (value == 'block') {
      cellColor = const Color.fromARGB(255, 170, 165, 159); // Block
    } else if (value == 'cloud') {
      cellColor = const Color.fromRGBO(173, 216, 230, 1); // Cloud
    } else if (value == 'gas') {
      cellColor = const Color.fromRGBO(245, 11, 148, 1); // Gas
    } else if (value == 'void') {
      cellColor = const Color.fromRGBO(30, 0, 0, 1); // Void
    } else if (value == 'clone') {
      cellColor = const Color.fromRGBO(255, 255, 0, 1); // Clone
    }

    return Container(decoration: BoxDecoration(color: cellColor));
  }

  void _handlePointerEvent(PointerEvent event) {
    final RenderBox? box =
        _gridKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return; // Prevent crashes if widget isn't rendered
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
      appBar: AppBar(
        title: const Text(
          'Elements Game',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Bold for cowboy accent
            color: Colors.white, // Clean, modern contrast
          ),
        ),
        backgroundColor: const Color(0xFF4A90E2), // Soft blue for Houston vibe
      ),
      body: Column(
        children: [
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _selectedElement,
              items: elements.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500, // Clean, modern typography
                      color: Colors.black87,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedElement = newValue!;
                });
              },
              style: const TextStyle(color: Colors.black87, fontSize: 16),
              dropdownColor: Colors.white, // White, clean Houston theme
              underline: Container(
                height: 2,
                color: const Color(0xFF4A90E2), // Subtle cowboy accent
              ),
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: Listener(
                key: _gridKey,
                onPointerDown: _handlePointerEvent,
                onPointerMove: _handlePointerEvent,
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
        ],
      ),
    );
  }
}
