import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:brubaker_homeapp/screens/star_field.dart'; // Only StarField remains
import 'package:provider/provider.dart';
import 'package:brubaker_homeapp/theme.dart';
import 'package:animate_do/animate_do.dart';

class GalacticCodebreakerScreen extends StatefulWidget {
  final Function(int) onGameSelected;

  const GalacticCodebreakerScreen({super.key, required this.onGameSelected});

  @override
  GalacticCodebreakerScreenState createState() =>
      GalacticCodebreakerScreenState();
}

class GalacticCodebreakerScreenState extends State<GalacticCodebreakerScreen> {
  final String serverUrl = 'http://192.168.1.198:6097';
  final Uuid uuid = Uuid();
  final Random random = Random();
  String? playerId;
  String? gamePin;
  bool isCreator = false;
  bool isSinglePlayer = false;
  List<String> secretCode = [];
  List<Map<String, dynamic>> guessHistory = [];
  List<String> currentGuess = ['', '', '', ''];
  bool isGameOver = false;
  bool isMyTurn = false;
  Timer? pollTimer;
  bool? _wasFeedbackHonest;
  int? _tempExact;
  int? _tempPartial;

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

  // Always galactic icons
  List<String> _getIcons() {
    return ['🌑', '⭐', '🪐', '☄️', '🌌', '🚀'];
  }

  // Galactic colors only
  Map<String, Color> _getColors(BuildContext context) {
    return {
      'background': Theme.of(context).scaffoldBackgroundColor,
      'surface': Theme.of(context).colorScheme.surface,
      'primary': Theme.of(context).primaryColor,
      'secondary': Theme.of(context).colorScheme.secondary,
      'text': Theme.of(context).textTheme.bodyLarge!.color!,
      'error': Colors.red,
      'success': Colors.green,
      'pending': Colors.orange,
    };
  }

  Future<void> _showRoleDialog() async {
    final colors = _getColors(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: FadeIn(
          duration: const Duration(milliseconds: 500),
          child: Text(
            'Galactic Codebreaker',
            style: GoogleFonts.orbitron(
              color: colors['text'],
              shadows: [
                Shadow(
                  color: colors['primary']!.withOpacity(0.4),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        backgroundColor: colors['surface']!.withOpacity(0.8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _startSinglePlayer();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors['primary']!.withOpacity(0.5),
                side: BorderSide(color: colors['primary']!.withOpacity(0.7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Play Single Player (Guess)',
                style: GoogleFonts.orbitron(color: colors['text']),
              ),
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _showSetCodeDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colors['secondary']!.withOpacity(0.5),
                side: BorderSide(color: colors['secondary']!.withOpacity(0.7)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Create Game (Set Code)',
                style: GoogleFonts.orbitron(color: colors['text']),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              decoration: InputDecoration(
                hintText: 'Enter PIN to Join (Guess)',
                hintStyle: TextStyle(color: colors['text']!.withOpacity(0.7)),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: colors['primary']!.withOpacity(0.5),
                  ),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: colors['primary']!),
                ),
              ),
              style: TextStyle(color: colors['text']),
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

  void _startSinglePlayer() {
    setState(() {
      isSinglePlayer = true;
      isCreator = false;
      isMyTurn = true;
      secretCode = List.generate(4, (_) => _getIcons()[random.nextInt(6)]);
      gamePin = null;
    });
  }

  Future<void> _showSetCodeDialog() async {
    final colors = _getColors(context);
    List<String> tempCode = ['', '', '', ''];
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: FadeIn(
                duration: const Duration(milliseconds: 500),
                child: Text(
                  'Set Secret Cosmic Code',
                  style: GoogleFonts.orbitron(
                    color: colors['text'],
                    shadows: [
                      Shadow(
                        color: colors['primary']!.withOpacity(0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              ),
              backgroundColor: colors['surface']!.withOpacity(0.8),
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
                        items: _getIcons()
                            .map(
                              (icon) => DropdownMenuItem(
                                value: icon,
                                child: Text(
                                  icon,
                                  style: const TextStyle(fontSize: 24),
                                ),
                              ),
                            )
                            .toList(),
                        dropdownColor: colors['surface']!.withOpacity(0.9),
                        style: TextStyle(color: colors['text'], fontSize: 24),
                        underline: Container(
                          height: 2,
                          color: colors['primary']!.withOpacity(0.5),
                        ),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors['primary']!.withOpacity(0.5),
                      side: BorderSide(
                        color: colors['primary']!.withOpacity(0.7),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Confirm and Create',
                      style: GoogleFonts.orbitron(color: colors['text']),
                    ),
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
    final colors = _getColors(context);
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
              style: GoogleFonts.orbitron(color: colors['error']),
            ),
            backgroundColor: colors['surface']!.withOpacity(0.8),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.orbitron(color: colors['text']),
                ),
              ),
            ],
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
            style: GoogleFonts.orbitron(color: colors['error']),
          ),
          backgroundColor: colors['surface']!.withOpacity(0.8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.orbitron(color: colors['text']),
              ),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _joinGame(String pin) async {
    final colors = _getColors(context);
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
              style: GoogleFonts.orbitron(color: colors['error']),
            ),
            backgroundColor: colors['surface']!.withOpacity(0.8),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.orbitron(color: colors['text']),
                ),
              ),
            ],
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
            style: GoogleFonts.orbitron(color: colors['error']),
          ),
          backgroundColor: colors['surface']!.withOpacity(0.8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.orbitron(color: colors['text']),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _startPolling() {
    pollTimer?.cancel();
    pollTimer = Timer.periodic(Duration(seconds: 2), (_) async {
      if (gamePin != null) {
        try {
          final response = await http.get(
            Uri.parse('$serverUrl/game-state?pin=$gamePin&playerId=$playerId'),
          );
          if (!mounted) return;
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            bool previousGameOver = isGameOver;
            setState(() {
              guessHistory = List<Map<String, dynamic>>.from(
                data['guessHistory'],
              );
              isGameOver = data['gameOver'];
              if (data.containsKey('code')) {
                secretCode = List<String>.from(data['code']);
              }
              isMyTurn =
                  !isGameOver &&
                  ((isCreator && data['pendingFeedback']) ||
                      (!isCreator && !data['pendingFeedback']));
            });
            if (isGameOver && !previousGameOver && !isSinglePlayer) {
              _checkFeedbackHonesty();
              _showSummaryDialog();
            }
          }
        } catch (e) {
          // Handle polling errors silently
        }
      }
    });
  }

  Future<void> _submitGuess() async {
    if (currentGuess.contains('') || isGameOver || !isMyTurn) return;
    bool previousGameOver = isGameOver;
    if (isSinglePlayer) {
      _provideLocalFeedback();
    } else {
      final colors = _getColors(context);
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
            isMyTurn = false;
          });
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(
                'Error submitting guess: ${response.statusCode} ${response.body}',
                style: GoogleFonts.orbitron(color: colors['error']),
              ),
              backgroundColor: colors['surface']!.withOpacity(0.8),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'OK',
                    style: GoogleFonts.orbitron(color: colors['text']),
                  ),
                ),
              ],
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
              style: GoogleFonts.orbitron(color: colors['error']),
            ),
            backgroundColor: colors['surface']!.withOpacity(0.8),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.orbitron(color: colors['text']),
                ),
              ),
            ],
          ),
        );
      }
    }
    if (isGameOver && !previousGameOver && isSinglePlayer) {
      _showSummaryDialog();
    }
  }

  void _provideLocalFeedback() {
    List<String> codeCopy = secretCode.toList();
    List<String> guessCopy = currentGuess.toList();
    int exact = 0;
    for (int i = 0; i < 4; i++) {
      if (guessCopy[i] == codeCopy[i]) {
        exact++;
        guessCopy[i] = '';
        codeCopy[i] = '';
      }
    }
    int partial = 0;
    for (int i = 0; i < 4; i++) {
      if (guessCopy[i].isNotEmpty && codeCopy.contains(guessCopy[i])) {
        partial++;
        codeCopy[codeCopy.indexOf(guessCopy[i])] = '';
      }
    }
    setState(() {
      guessHistory.add({
        'guess': currentGuess.toList(),
        'feedback': {'exact': exact, 'partial': partial},
      });
      currentGuess = ['', '', '', ''];
      if (exact == 4 || guessHistory.length >= 10) {
        isGameOver = true;
      }
    });
  }

  Future<void> _submitFeedback(int exact, int partial) async {
    final colors = _getColors(context);
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/submit-feedback'),
        body: jsonEncode({
          'pin': gamePin,
          'playerId': playerId,
          'exact': exact,
          'partial': partial,
        }),
        headers: {'Content-Type': 'application/json'},
      );
      if (!mounted) return;
      if (response.statusCode != 200) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Error submitting feedback: ${response.statusCode} ${response.body}',
              style: GoogleFonts.orbitron(color: colors['error']),
            ),
            backgroundColor: colors['surface']!.withOpacity(0.8),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'OK',
                  style: GoogleFonts.orbitron(color: colors['text']),
                ),
              ),
            ],
          ),
        );
      } else {
        setState(() {
          _tempExact = null;
          _tempPartial = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            'Network error: $e',
            style: GoogleFonts.orbitron(color: colors['error']),
          ),
          backgroundColor: colors['surface']!.withOpacity(0.8),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'OK',
                style: GoogleFonts.orbitron(color: colors['text']),
              ),
            ),
          ],
        ),
      );
    }
  }

  void _checkFeedbackHonesty() {
    bool honest = true;
    for (var hist in guessHistory) {
      List<String> codeCopy = secretCode.toList();
      List<String> guessCopy = List<String>.from(hist['guess']);
      int calculatedExact = 0;
      for (int i = 0; i < 4; i++) {
        if (guessCopy[i] == codeCopy[i]) {
          calculatedExact++;
          guessCopy[i] = '';
          codeCopy[i] = '';
        }
      }
      int calculatedPartial = 0;
      for (int i = 0; i < 4; i++) {
        if (guessCopy[i].isNotEmpty && codeCopy.contains(guessCopy[i])) {
          calculatedPartial++;
          codeCopy[codeCopy.indexOf(guessCopy[i])] = '';
        }
      }
      if (calculatedExact != hist['feedback']['exact'] ||
          calculatedPartial != hist['feedback']['partial']) {
        honest = false;
        break;
      }
    }
    setState(() {
      _wasFeedbackHonest = honest;
    });
  }

  void _showSummaryDialog() {
    final colors = _getColors(context);
    String message;
    bool won =
        guessHistory.isNotEmpty && guessHistory.last['feedback']['exact'] == 4;
    if (isCreator) {
      if (won) {
        message = 'The guesser cracked your cosmic code!';
      } else {
        message = 'The guesser ran out of guesses - you win!';
      }
    } else {
      if (won) {
        message =
            'Congratulations! You cracked the code in ${guessHistory.length} guesses!';
      } else {
        message = 'Out of guesses! Better luck next time.';
      }
      if (!isSinglePlayer && _wasFeedbackHonest == false) {
        message += '\nBut the feedback was dishonest - no fair play!';
      }
    }
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors['surface']!.withOpacity(0.8),
        title: FadeIn(
          duration: const Duration(milliseconds: 500),
          child: Text(
            message,
            style: GoogleFonts.orbitron(
              color: won ? colors['success'] : colors['error'],
              shadows: [
                Shadow(
                  color:
                      Theme.of(context).scaffoldBackgroundColor ==
                          const Color(0xFF1C2526)
                      ? Colors.purple[900]!.withOpacity(0.4)
                      : colors['primary']!.withOpacity(0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.orbitron(color: colors['text']),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [colors['background']!, colors['surface']!],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: StarField(opacity: 0.4)),
            SafeArea(
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.arrow_back, color: colors['text']),
                        onPressed: () => widget.onGameSelected(0),
                      ),
                      if (gamePin != null)
                        FadeIn(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            'PIN: $gamePin',
                            style: GoogleFonts.orbitron(
                              fontSize: 16,
                              color: colors['text']!.withOpacity(0.7),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (isCreator)
                    Column(
                      children: [
                        FadeIn(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            Theme.of(context).scaffoldBackgroundColor ==
                                    const Color(0xFF1C2526)
                                ? 'Awaiting Ghoulish Guesses'
                                : 'Waiting for Guesses',
                            style: GoogleFonts.orbitron(
                              fontSize: 20,
                              color: colors['text'],
                              shadows: [
                                Shadow(
                                  color: colors['primary']!.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Text(
                          '(Code: ${secretCode.join(' ')})',
                          style: GoogleFonts.orbitron(
                            fontSize: 16,
                            color: colors['text']!.withOpacity(0.7),
                          ),
                        ),
                      ],
                    )
                  else
                    FadeIn(
                      duration: const Duration(milliseconds: 500),
                      child: Text(
                        Theme.of(context).scaffoldBackgroundColor ==
                                const Color(0xFF1C2526)
                            ? 'Unravel the Haunted Code'
                            : 'Make Your Guess',
                        style: GoogleFonts.orbitron(
                          fontSize: 20,
                          color: colors['text'],
                          shadows: [
                            Shadow(
                              color: colors['primary']!.withOpacity(0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
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
                            style: TextStyle(
                              color: colors['text'],
                              fontSize: 24,
                            ),
                          ),
                          trailing: hist['feedback'] != null
                              ? Text(
                                  'Exact: ${hist['feedback']['exact']} Partial: ${hist['feedback']['partial']}',
                                  style: TextStyle(color: colors['success']),
                                )
                              : Flash(
                                  duration: const Duration(milliseconds: 600),
                                  child: Text(
                                    'Pending Feedback',
                                    style: TextStyle(color: colors['pending']),
                                  ),
                                ),
                        );
                      },
                    ),
                  ),
                  if (!isGameOver &&
                      isCreator &&
                      guessHistory.isNotEmpty &&
                      guessHistory.last['feedback'] == null)
                    Column(
                      children: [
                        Text(
                          'Provide Feedback for Guess: ${guessHistory.last['guess'].join(' ')}',
                          style: GoogleFonts.orbitron(color: colors['text']),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Exact: ',
                              style: TextStyle(color: colors['text']),
                            ),
                            DropdownButton<int>(
                              value: _tempExact,
                              onChanged: (value) =>
                                  setState(() => _tempExact = value),
                              items: List.generate(
                                5,
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                    '$i',
                                    style: TextStyle(color: colors['text']),
                                  ),
                                ),
                              ),
                              dropdownColor: colors['surface']!.withOpacity(
                                0.9,
                              ),
                              style: TextStyle(color: colors['text']),
                              underline: Container(
                                height: 2,
                                color: colors['primary']!.withOpacity(0.5),
                              ),
                            ),
                            Text(
                              ' Partial: ',
                              style: TextStyle(color: colors['text']),
                            ),
                            DropdownButton<int>(
                              value: _tempPartial,
                              onChanged: (value) =>
                                  setState(() => _tempPartial = value),
                              items: List.generate(
                                5,
                                (i) => DropdownMenuItem(
                                  value: i,
                                  child: Text(
                                    '$i',
                                    style: TextStyle(color: colors['text']),
                                  ),
                                ),
                              ),
                              dropdownColor: colors['surface']!.withOpacity(
                                0.9,
                              ),
                              style: TextStyle(color: colors['text']),
                              underline: Container(
                                height: 2,
                                color: colors['primary']!.withOpacity(0.5),
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton(
                          onPressed:
                              (_tempExact != null && _tempPartial != null)
                              ? () =>
                                    _submitFeedback(_tempExact!, _tempPartial!)
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors['primary']!.withOpacity(
                              0.5,
                            ),
                            side: BorderSide(
                              color: colors['primary']!.withOpacity(0.7),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Submit Feedback',
                            style: GoogleFonts.orbitron(color: colors['text']),
                          ),
                        ),
                      ],
                    ),
                  if (!isCreator &&
                      !isGameOver &&
                      !isSinglePlayer &&
                      guessHistory.isNotEmpty &&
                      guessHistory.last['feedback'] == null)
                    Flash(
                      duration: const Duration(milliseconds: 600),
                      child: Text(
                        'Waiting for Feedback...',
                        style: GoogleFonts.orbitron(
                          color: colors['text']!.withOpacity(0.7),
                        ),
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
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colors['secondary']!.withOpacity(
                              0.5,
                            ),
                            side: BorderSide(
                              color: colors['secondary']!.withOpacity(0.7),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Submit Guess',
                            style: GoogleFonts.orbitron(color: colors['text']),
                          ),
                        ),
                      ],
                    ),
                  if (isGameOver)
                    Column(
                      children: [
                        FadeIn(
                          duration: const Duration(milliseconds: 500),
                          child: Text(
                            'Game Over! Code was ${secretCode.join(' ')}',
                            style: GoogleFonts.orbitron(
                              fontSize: 24,
                              color: colors['error'],
                              shadows: [
                                Shadow(
                                  color:
                                      Theme.of(
                                            context,
                                          ).scaffoldBackgroundColor ==
                                          const Color(0xFF1C2526)
                                      ? Colors.purple[900]!.withOpacity(0.4)
                                      : colors['primary']!.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                        ),
                        if (_wasFeedbackHonest == false)
                          Text(
                            Theme.of(context).scaffoldBackgroundColor ==
                                    const Color(0xFF1C2526)
                                ? 'Cursed feedback - spirits deceived you!'
                                : 'Feedback was inaccurate - no fair play!',
                            style: GoogleFonts.orbitron(
                              color: colors['error'],
                              shadows: [
                                Shadow(
                                  color:
                                      Theme.of(
                                            context,
                                          ).scaffoldBackgroundColor ==
                                          const Color(0xFF1C2526)
                                      ? Colors.purple[900]!.withOpacity(0.4)
                                      : colors['primary']!.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                      ],
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
    final colors = _getColors(context);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: DropdownButton<String>(
        value: currentGuess[index].isEmpty ? null : currentGuess[index],
        onChanged: (value) => setState(() => currentGuess[index] = value!),
        items: _getIcons()
            .map(
              (icon) => DropdownMenuItem(
                value: icon,
                child: Text(icon, style: const TextStyle(fontSize: 24)),
              ),
            )
            .toList(),
        dropdownColor: colors['surface']!.withOpacity(0.9),
        style: TextStyle(color: colors['text'], fontSize: 24),
        underline: Container(
          height: 2,
          color: colors['primary']!.withOpacity(0.5),
        ),
      ),
    );
  }

  void _showPinShareDialog(String pin) {
    final colors = _getColors(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: colors['surface']!.withOpacity(0.8),
        title: FadeIn(
          duration: const Duration(milliseconds: 500),
          child: Text(
            'Share PIN: $pin',
            style: GoogleFonts.orbitron(color: colors['text']),
          ),
        ),
        content: Text(
          'Give this to your opponent to join and guess!',
          style: GoogleFonts.orbitron(color: colors['text']!.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.orbitron(color: colors['text']),
            ),
          ),
        ],
      ),
    );
  }
}
