import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart' as animate_do;
import '../screens/star_field.dart';
import 'dart:async';
import 'dart:ui';

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  InfoScreenState createState() => InfoScreenState();
}

class InfoScreenState extends State<InfoScreen> {
  late Timer _timer;
  String _countdownMode = 'days';
  String _countdownText = '';
  final DateTime anniversaryDate = DateTime(2026, 5, 3);

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final difference = anniversaryDate.difference(now);

    setState(() {
      if (_countdownMode == 'days') {
        _countdownText = '${difference.inDays} galactic days';
      } else if (_countdownMode == 'coffee_thursdays') {
        final thursdays = _calculateCoffeeThursdays(now);
        _countdownText = '$thursdays Coffee Thursdays ☕';
      } else if (_countdownMode == 'paychecks') {
        final paychecks = _calculatePaychecks(now);
        _countdownText = '$paychecks paydays 💸';
      } else if (_countdownMode == 'time') {
        final hours = difference.inHours;
        final minutes = difference.inMinutes % 60;
        final seconds = difference.inSeconds % 60;
        _countdownText =
            '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
    });
  }

  int _calculateCoffeeThursdays(DateTime now) {
    final thursday = now.weekday == DateTime.thursday
        ? now
        : now.subtract(Duration(days: now.weekday - DateTime.thursday));
    int weeks = 0;
    DateTime current = thursday;
    while (current.isBefore(anniversaryDate)) {
      weeks++;
      current = current.add(const Duration(days: 7));
    }
    return weeks;
  }

  int _calculatePaychecks(DateTime now) {
    final daysUntil = anniversaryDate.difference(now).inDays;
    return (daysUntil / 14).ceil();
  }

  void _showHouseInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'House Info',
                    style: GoogleFonts.orbitron(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    leading: const Icon(
                      Icons.coffee_maker,
                      color: Colors.white70,
                    ),
                    title: Text(
                      'How to Use Coffee Machine',
                      style: GoogleFonts.orbitron(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showPlaceholderDialog(context, 'Coffee Machine');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.wifi, color: Colors.white70),
                    title: Text(
                      'WiFi Setup',
                      style: GoogleFonts.orbitron(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showPlaceholderDialog(context, 'WiFi Setup');
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.home, color: Colors.white70),
                    title: Text(
                      'House Rules',
                      style: GoogleFonts.orbitron(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _showPlaceholderDialog(context, 'House Rules');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.orbitron(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  void _showPlaceholderDialog(BuildContext context, String title) {
    Widget content;
    if (title == 'House Rules') {
      content = Text(
        '1. No audible tooth-brushing around Willoh.\n'
        '2. Chew with your mouth shut.\n'
        '3. See rule 1.\n'
        '4. Lorax talk must include its political economy vibes.',
        style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 14),
      );
    } else if (title == 'Coffee Machine') {
      content = Text(
        'Grind beans to a slightly coarse texture, press into a pod, and run the machine.',
        style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 14),
      );
    } else if (title == 'WiFi Setup') {
      content = Text(
        'WiFi Name: BrubakerWifi\nPassword: Pre\$ton01',
        style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 14),
      );
    } else {
      content = Text(
        'No information available',
        style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 14),
      );
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.orbitron(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 12),
                  content,
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'OK',
              style: GoogleFonts.orbitron(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A1E).withValues(alpha: 0.9),
              Color(0xFF1A1A3A).withValues(alpha: 0.7),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: StarField(opacity: 0.3)),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    animate_do.FadeIn(
                      duration: const Duration(milliseconds: 800),
                      child: Text(
                        '2 Years!! 🎉',
                        style: GoogleFonts.orbitron(
                          color: Colors.white70,
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          shadows: [
                            Shadow(
                              color: Colors.purpleAccent.withValues(alpha: 0.5),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (_countdownMode == 'days')
                      animate_do.BounceIn(
                        duration: const Duration(milliseconds: 600),
                        child: Text(
                          _countdownText,
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 20,
                            shadows: [
                              Shadow(
                                color: Colors.cyanAccent.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_countdownMode == 'coffee_thursdays')
                      animate_do.JelloIn(
                        duration: const Duration(milliseconds: 800),
                        child: Text(
                          _countdownText,
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 20,
                            shadows: [
                              Shadow(
                                color: Colors.greenAccent.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (_countdownMode == 'paychecks')
                      animate_do.Swing(
                        duration: const Duration(milliseconds: 1000),
                        child: Text(
                          _countdownText,
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 20,
                            shadows: [
                              Shadow(
                                color: Colors.yellowAccent.withValues(
                                  alpha: 0.4,
                                ),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      animate_do.Pulse(
                        duration: const Duration(milliseconds: 600),
                        child: Text(
                          _countdownText,
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 20,
                            shadows: [
                              Shadow(
                                color: Colors.redAccent.withValues(alpha: 0.4),
                                blurRadius: 6,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildModeButton('Days', 'days', 'BounceIn'),
                        _buildModeButton(
                          'Coffee Thursdays',
                          'coffee_thursdays',
                          'JelloIn',
                        ),
                        _buildModeButton('Paychecks', 'paychecks', 'Swing'),
                        _buildModeButton('Time', 'time', 'Pulse'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        elevation: 8,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.purpleAccent.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Icon(Icons.info_outline, color: Colors.white70),
        ),
        onPressed: () => _showHouseInfoDialog(context),
      ),
    );
  }

  Widget _buildModeButton(String label, String mode, String animationType) {
    Widget button = ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _countdownMode == mode
            ? Colors.white.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: _countdownMode == mode
                ? Colors.white.withValues(alpha: 0.8)
                : Colors.white.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        elevation: 6,
      ),
      onPressed: () {
        setState(() {
          _countdownMode = mode;
          _updateCountdown();
        });
      },
      child: Text(
        label,
        style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 14),
      ),
    );

    switch (animationType) {
      case 'BounceIn':
        return animate_do.BounceIn(
          duration: const Duration(milliseconds: 600),
          child: button,
        );
      case 'JelloIn':
        return animate_do.JelloIn(
          duration: const Duration(milliseconds: 800),
          child: button,
        );
      case 'Swing':
        return animate_do.Swing(
          duration: const Duration(milliseconds: 1000),
          child: button,
        );
      case 'Pulse':
        return animate_do.Pulse(
          duration: const Duration(milliseconds: 600),
          child: button,
        );
      default:
        return button;
    }
  }
}
