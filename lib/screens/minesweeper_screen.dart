import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

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
                  _board = (jsonData['board'] as List).map((row) => (row as List).cast<dynamic>()).toList();
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
      _socket!.write(jsonEncode(action) + '\n');
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
      cellColor = Colors.grey;
    } else if (value == 'flag') {
      icon = Icons.flag;
      cellColor = Colors.yellow;
    } else if (value == 'mine') {
      icon = Icons.warning;
      cellColor = Colors.red;
    } else if (value is int) {
      text = value > 0 ? value.toString() : '';
      cellColor = Colors.blueGrey;
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
          border: Border.all(color: Colors.black),
        ),
        child: Center(
          child: icon != null
              ? Icon(icon, color: Colors.black)
              : Text(
                  text,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Minesweeper'),
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
          if (_isLoading || _board.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            Expanded(
              child: GridView.builder(
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
          Text('Status: $_status'),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => _sendAction({'action': 'new_game'}),
            child: const Text('Start New Game'),
          ),
        ],
      ),
    );
  }
}