import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';

class IndianNameScreen extends StatefulWidget {
  const IndianNameScreen({super.key});

  @override
  _IndianNameScreenState createState() => _IndianNameScreenState();
}

class _IndianNameScreenState extends State<IndianNameScreen> {
  String _epochTime = '';
  String _randomNumber = '';
  String _numVisits = '';
  String _tribalName = '';
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _epochTime = '';
      _randomNumber = '';
      _numVisits = '';
      _tribalName = '';
    });

    try {
      final socket = await Socket.connect('192.168.1.126', 5090);
      socket.listen(
        (List<int> data) {
          final response = utf8.decode(data);
          final jsonData = jsonDecode(response);
          setState(() {
            _epochTime = jsonData['epoch_time']?.toString() ?? 'N/A';
            _randomNumber = jsonData['random_number']?.toString() ?? 'N/A';
            _numVisits = jsonData['num visits']?.toString() ?? 'N/A';
            _tribalName = jsonData['tribal name'] ?? 'N/A';
            _isLoading = false;
          });
          socket.destroy();
        },
        onError: (error) {
          setState(() {
            _errorMessage = 'Error receiving data: $error';
            _isLoading = false;
          });
          socket.destroy();
        },
        onDone: () {
          socket.destroy();
        },
      );
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Silly Name'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_errorMessage.isNotEmpty)
              Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            if (_isLoading)
              const CircularProgressIndicator()
            else if (_tribalName.isNotEmpty) ...[
              Text('Epoch Time: $_epochTime'),
              Text('Random Number: $_randomNumber'),
              Text('Num Visits: $_numVisits'),
              Text('Silly Name: $_tribalName'),
            ] else
              const Text('Press the button to fetch data from the server'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isLoading ? null : _fetchData,
              child: const Text('Fetch Data'),
            ),
          ],
        ),
      ),
    );
  }
}