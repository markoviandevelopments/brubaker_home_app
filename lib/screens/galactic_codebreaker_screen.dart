import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:brubaker_homeapp/screens/star_field.dart';

class GalacticCodebreakerScreen extends StatefulWidget {
  final Function(int) onGameSelected;

  const GalacticCodebreakerScreen({super.key, required this.onGameSelected});

  @override
  GalacticCodebreakerScreenState createState() =>
      GalacticCodebreakerScreenState();
}

class GalacticCodebreakerScreenState extends State<GalacticCodebreakerScreen> {
  final String serverUrl = 'http://192.168.1.126:6097';
  final Uuid uuid = Uuid();
  String? playerId;
  String? gamePin;
  bool isCreator = false;
  List<String> secretCode = [];
  List<Map<String, dynamic>> guessHistory = [];
  List<String> currentGuess = ['', '', '', ''];
  bool isGameOver = false;
  bool isMyTurn = false;
  Timer? pollTimer;

  final List<String> possibleIcons = ['🔴', '🔵', '🟢', '🟡', '🟣', '🟠'];

  @override
  void initState() {
    super.initState();
    playerId = uuid.v4();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _showRoleDialog();
    });
  }

  @override
  void dispose() {
    pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _showRoleDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Galactic Codebreaker',
          style: GoogleFonts.orbitron(color: Colors.white),
        ),
        backgroundColor: Color(0xFF1A1A3A),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showSetCodeDialog();
              },
              child: Text('Create Game (Set Code)'),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter PIN to Join (Guess)',
                hintStyle: TextStyle(color: Colors.white70),
              ),
              style: TextStyle(color: Colors.white),
              onSubmitted: (pin) {
                Navigator.pop(context);
                _joinGame(pin);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSetCodeDialog() async {
    List<String> tempCode = ['', '', '', ''];
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: Text(
                'Set Secret Cosmic Code',
                style: GoogleFonts.orbitron(color: Colors.white),
              ),
              backgroundColor: Color(0xFF1A1A3A),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      4,
                      (i) => DropdownButton<String>(
                        value: tempCode[i].isEmpty ? null : tempCode[i],
                        onChanged: (value) {
                          setDialogState(() {
                            tempCode[i] = value!;
                          });
                        },
                        items: possibleIcons
                            .map(
                              (icon) => DropdownMenuItem(
                                value: icon,
                                child: Text(icon),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: tempCode.contains('')
                        ? null
                        : () {
                            Navigator.pop(dialogContext);
                            _createGame(tempCode);
                          },
                    child: Text('Confirm and Create'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _createGame(List<String> code) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/create-game'),
        body: jsonEncode({'playerId': playerId, 'code': code}),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          gamePin = data['pin'];
          secretCode = code;
          isCreator = true;
          isMyTurn = false;
        });
        _startPolling();
        _showPinShareDialog(data['pin']);
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Error creating game: ${response.statusCode} ${response.body}',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF1A1A3A),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Network error: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF1A1A3A),
        ),
      );
    }
  }

  Future<void> _joinGame(String pin) async {
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/join-game'),
        body: jsonEncode({'pin': pin, 'playerId': playerId}),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          gamePin = pin;
          guessHistory = List<Map<String, dynamic>>.from(data['guessHistory']);
          isGameOver = data['gameOver'];
          if (data.containsKey('code')) {
            secretCode = List<String>.from(data['code']);
          }
          isMyTurn = true;
          isCreator = false;
        });
        _startPolling();
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Error joining game: ${response.statusCode} ${response.body}',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF1A1A3A),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Network error: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF1A1A3A),
        ),
      );
    }
  }

  void _startPolling() {
    pollTimer = Timer.periodic(Duration(seconds: 2), (_) async {
      if (gamePin != null) {
        try {
          final response = await http.get(
            Uri.parse('$serverUrl/game-state?pin=$gamePin&playerId=$playerId'),
          );
          if (!mounted) return;
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            setState(() {
              guessHistory = List<Map<String, dynamic>>.from(
                data['guessHistory'],
              );
              isGameOver = data['gameOver'];
              if (data.containsKey('code')) {
                secretCode = List<String>.from(data['code']);
              }
              isMyTurn = !isCreator && !isGameOver;
            });
          }
        } catch (e) {
          // Optionally handle polling errors silently or log
        }
      }
    });
  }

  Future<void> _submitGuess() async {
    if (currentGuess.contains('') || isGameOver || !isMyTurn) return;
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/submit-guess'),
        body: jsonEncode({
          'pin': gamePin,
          'playerId': playerId,
          'guess': currentGuess,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() {
          currentGuess = ['', '', '', ''];
        });
      } else {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Error submitting guess: ${response.statusCode} ${response.body}',
              style: TextStyle(color: Colors.white),
            ),
            backgroundColor: Color(0xFF1A1A3A),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Network error: $e',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Color(0xFF1A1A3A),
        ),
      );
    }
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
            Positioned.fill(child: StarField(opacity: 0.4)),
            SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back),
                        color: Colors.white,
                        onPressed: () => widget.onGameSelected(0),
                      ),
                    ],
                  ),
                  Text(
                    isCreator
                        ? 'Waiting for Guesses (Code: ${secretCode.join(' ')})'
                        : 'Make Your Guess',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      color: Colors.white,
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: guessHistory.length,
                      itemBuilder: (context, index) {
                        final hist = guessHistory[index];
                        return ListTile(
                          title: Text(
                            hist['guess'].join(' '),
                            style: TextStyle(color: Colors.white),
                          ),
                          trailing: Text(
                            'Exact: ${hist['feedback']['exact']} Partial: ${hist['feedback']['partial']}',
                            style: TextStyle(color: Colors.yellow),
                          ),
                        );
                      },
                    ),
                  ),
                  if (!isCreator && !isGameOver)
                    Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(4, (i) => _buildGuessSlot(i)),
                        ),
                        ElevatedButton(
                          onPressed: _submitGuess,
                          child: Text('Submit Guess'),
                        ),
                      ],
                    ),
                  if (isGameOver)
                    Text(
                      'Game Over! Code was ${secretCode.join(' ')}',
                      style: GoogleFonts.orbitron(
                        fontSize: 24,
                        color: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuessSlot(int index) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButton<String>(
        value: currentGuess[index].isEmpty ? null : currentGuess[index],
        onChanged: (value) => setState(() => currentGuess[index] = value!),
        items: possibleIcons
            .map((icon) => DropdownMenuItem(value: icon, child: Text(icon)))
            .toList(),
      ),
    );
  }

  void _showPinShareDialog(String pin) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1A1A3A),
        title: Text(
          'Share PIN: $pin',
          style: GoogleFonts.orbitron(color: Colors.white),
        ),
        content: Text(
          'Give this to your opponent to join and guess!',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
