import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class ElementsScreen extends StatefulWidget {
  const ElementsScreen({super.key});

  @override
  _ElementsScreenState createState() => _ElementsScreenState();
}

class _ElementsScreenState extends State<ElementsScreen> {
  Socket? _socket;
  List<List<String>> _grid = List.generate(
    20,
    (_) => List.generate(20, (_) => 'nothing'),
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
  ];

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
        _grid = List.generate(20, (_) => List.generate(20, (_) => 'nothing'));
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
    Color cellColor = const Color.fromARGB(255, 48, 48, 48); // Nothing

    if (value == 'sand') {
      cellColor = const Color.fromARGB(255, 255, 239, 206); // Sand
    } else if (value == 'water') {
      cellColor = const Color.fromARGB(255, 59, 135, 211); // Water
    } else if (value == 'block') {
      cellColor = const Color.fromARGB(255, 170, 165, 159); // Block
    } else if (value == 'cloud') {
      cellColor = const Color.fromRGBO(173, 216, 230, 1);
    } else if (value == 'gas') {
      cellColor = const Color.fromRGBO(245, 11, 148, 1);
    }

    return GestureDetector(
      onTap: () {
        _sendAction({
          'action': 'place',
          'x': col,
          'y': row,
          'element': _selectedElement,
        });
      },
      onPanStart: (details) {
        _sendAction({
          'action': 'place',
          'x': col,
          'y': row,
          'element': _selectedElement,
        });
      },
      onPanUpdate: (details) {
        RenderBox box = context.findRenderObject() as RenderBox;
        Offset localPosition = box.globalToLocal(details.globalPosition);
        int newRow = (localPosition.dy / (box.size.height / 20)).floor();
        int newCol = (localPosition.dx / (box.size.width / 20)).floor();

        if (newRow >= 0 && newRow < 20 && newCol >= 0 && newCol < 20) {
          if (newRow != row || newCol != col) {
            _sendAction({
              'action': 'place',
              'x': newCol,
              'y': newRow,
              'element': _selectedElement,
            });
          }
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cellColor,
          border: Border.all(color: Colors.black, width: 0.5),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elements Game'),
        backgroundColor: Colors.blue, // Modern, clean Houston vibe
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
                  child: Text(value),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedElement = newValue!;
                });
              },
            ),
          ),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 20,
                  childAspectRatio: 1,
                ),
                itemCount: 20 * 20,
                itemBuilder: (context, index) {
                  final row = index ~/ 20;
                  final col = index % 20;
                  return _buildCell(row, col);
                },
              ),
            ),
        ],
      ),
    );
  }
}
