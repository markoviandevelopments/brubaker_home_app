import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart' as animate_do;
import 'dart:async';
import 'dart:ui';
import 'dart:math' show pi, cos, sin;
import 'package:brubaker_homeapp/screens/star_field.dart'; // Import StarField from star_field.dart

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  InfoScreenState createState() => InfoScreenState();
}

class InfoScreenState extends State<InfoScreen> with TickerProviderStateMixin {
  late Timer _timer;
  String _countdownMode = 'days';
  String _countdownText = '';
  final DateTime anniversaryDate = DateTime(2026, 5, 3);
  late AnimationController _orbitController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _updateCountdown();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateCountdown(),
    );

    // Orbit animation for buttons
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    // Glow effect for floating action button
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _orbitController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _updateCountdown() {
    final now = DateTime.now();
    final difference = anniversaryDate.difference(now);

    setState(() {
      if (_countdownMode == 'days') {
        _countdownText = '${difference.inDays} Galactic Cycles';
      } else if (_countdownMode == 'coffee_thursdays') {
        final thursdays = _calculateCoffeeThursdays(now);
        _countdownText = '$thursdays Nebula Brews ☕';
      } else if (_countdownMode == 'paychecks') {
        final paychecks = _calculatePaychecks(now);
        _countdownText = '$paychecks Stardust Credits 💸';
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
      builder: (context) => animate_do.FadeIn(
        duration: const Duration(milliseconds: 600),
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          content: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.blueAccent.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    radius: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.cyanAccent.withValues(alpha: 0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.cyanAccent.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Starbase Protocols',
                      style: GoogleFonts.orbitron(
                        color: Colors.cyanAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        shadows: [
                          Shadow(
                            color: Colors.cyanAccent.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildDialogOption(
                      context,
                      icon: Icons.coffee_maker,
                      title: 'Nebula Brew Station',
                      onTap: () => _showPlaceholderDialog(
                        context,
                        'Nebula Brew Station',
                      ),
                    ),
                    _buildDialogOption(
                      context,
                      icon: Icons.wifi,
                      title: 'Quantum Network',
                      onTap: () =>
                          _showPlaceholderDialog(context, 'Quantum Network'),
                    ),
                    _buildDialogOption(
                      context,
                      icon: Icons.shield,
                      title: 'Starbase Rules',
                      onTap: () =>
                          _showPlaceholderDialog(context, 'Starbase Rules'),
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
                'Disengage',
                style: GoogleFonts.orbitron(color: Colors.cyanAccent),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return animate_do.BounceIn(
      duration: const Duration(milliseconds: 800),
      child: ListTile(
        leading: Icon(icon, color: Colors.cyanAccent),
        title: Text(
          title,
          style: GoogleFonts.orbitron(
            color: Colors.white,
            fontSize: 16,
            shadows: [
              Shadow(
                color: Colors.cyanAccent.withValues(alpha: 0.3),
                blurRadius: 5,
              ),
            ],
          ),
        ),
        onTap: onTap,
      ),
    );
  }

  void _showPlaceholderDialog(BuildContext context, String title) {
    Widget content;
    if (title == 'Starbase Rules') {
      content = Text(
        '1. No sonic tooth-brushing near Willoh’s orbit.\n'
        '2. Maintain stealth chewing protocols.\n'
        '3. See rule 1.\n'
        '4. Lorax discussions must explore its interstellar political economy.',
        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
      );
    } else if (title == 'Nebula Brew Station') {
      content = Text(
        'Grind cosmic beans to a pulsar texture, compress into a pod, and activate the brew core.',
        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
      );
    } else if (title == 'Quantum Network') {
      content = Text(
        'Network: BrubakerNebula\nPasscode: Star\$ton01',
        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
      );
    } else {
      content = Text(
        'No data in this sector.',
        style: GoogleFonts.orbitron(color: Colors.white, fontSize: 14),
      );
    }

    showDialog(
      context: context,
      builder: (context) => animate_do.ZoomIn(
        duration: const Duration(milliseconds: 600),
        child: AlertDialog(
          backgroundColor: Colors.transparent,
          content: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      Colors.purpleAccent.withValues(alpha: 0.3),
                      Colors.black.withValues(alpha: 0.7),
                    ],
                    radius: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.purpleAccent.withValues(alpha: 0.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.orbitron(
                        color: Colors.purpleAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        shadows: [
                          Shadow(
                            color: Colors.purpleAccent.withValues(alpha: 0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
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
                'Return to Orbit',
                style: GoogleFonts.orbitron(color: Colors.purpleAccent),
              ),
            ),
          ],
        ),
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
            colors: [Colors.black, Colors.indigo.shade900],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: StarField(
                opacity: 0.7,
              ), // Use StarField from star_field.dart, increased opacity for better visibility
            ),
            Positioned.fill(child: _buildOrbitingPlanets()),
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    animate_do.Spin(
                      duration: const Duration(seconds: 20),
                      child: Text(
                        'Countdown to 2nd Anniversary! 🌌',
                        style: GoogleFonts.orbitron(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 28,
                          shadows: [
                            Shadow(
                              color: Colors.blueAccent.withValues(alpha: 0.7),
                              blurRadius: 15,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildCountdownDisplay(),
                    const SizedBox(height: 30),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildModeButton(
                          'Galactic Cycles',
                          'days',
                          Colors.cyanAccent,
                          'Spin',
                          1.0,
                          0.0,
                        ),
                        _buildModeButton(
                          'Nebula Brews',
                          'coffee_thursdays',
                          Colors.greenAccent,
                          'Bounce',
                          1.0,
                          pi / 2,
                        ),
                        _buildModeButton(
                          'Stardust Credits',
                          'paychecks',
                          Colors.yellowAccent,
                          'Pulse',
                          1.0,
                          pi,
                        ),
                        _buildModeButton(
                          'Quantum Time',
                          'time',
                          Colors.redAccent,
                          'ZoomIn',
                          1.0,
                          3 * pi / 2,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.2).animate(
          CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.black.withValues(
            alpha: 0.7,
          ), // Increased opacity for better visibility
          elevation: 10,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.cyanAccent.withValues(alpha: 0.8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.cyanAccent.withValues(alpha: 0.6),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: const Icon(
              Icons.info_outline,
              color: Colors.cyanAccent,
              size: 30,
            ),
          ),
          onPressed: () => _showHouseInfoDialog(context),
        ),
      ),
    );
  }

  Widget _buildCountdownDisplay() {
    Color glowColor;
    String animationType;

    switch (_countdownMode) {
      case 'days':
        glowColor = Colors.cyanAccent;
        animationType = 'Spin';
        break;
      case 'coffee_thursdays':
        glowColor = Colors.greenAccent;
        animationType = 'Bounce';
        break;
      case 'paychecks':
        glowColor = Colors.yellowAccent;
        animationType = 'Pulse';
        break;
      case 'time':
        glowColor = Colors.redAccent;
        animationType = 'ZoomIn';
        break;
      default:
        glowColor = Colors.white;
        animationType = 'FadeIn';
    }

    Widget text = Text(
      _countdownText,
      style: GoogleFonts.orbitron(
        color: Colors.white,
        fontSize: 24,
        shadows: [
          Shadow(
            color: glowColor.withValues(alpha: 0.7), // Increased glow opacity
            blurRadius: 15, // Slightly increased blur for better effect
            offset: const Offset(0, 2),
          ),
        ],
      ),
    );

    switch (animationType) {
      case 'Spin':
        return animate_do.Spin(
          duration: const Duration(seconds: 15),
          child: text,
        );
      case 'Bounce':
        return animate_do.Bounce(
          duration: const Duration(milliseconds: 1000),
          child: text,
        );
      case 'Pulse':
        return animate_do.Pulse(
          duration: const Duration(milliseconds: 800),
          child: text,
        );
      case 'ZoomIn':
        return animate_do.ZoomIn(
          duration: const Duration(milliseconds: 600),
          child: text,
        );
      default:
        return animate_do.FadeIn(
          duration: const Duration(milliseconds: 600),
          child: text,
        );
    }
  }

  Widget _buildModeButton(
    String label,
    String mode,
    Color planetColor,
    String animationType,
    double orbitSpeed,
    double phase,
  ) {
    return AnimatedBuilder(
      animation: _orbitController,
      builder: (context, child) {
        final angle = (_orbitController.value * 2 * pi * orbitSpeed) + phase;
        final offset = Offset(cos(angle) * 20, sin(angle) * 20);
        return Transform.translate(
          offset: offset,
          child: animate_do.BounceIn(
            duration: const Duration(milliseconds: 800),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: planetColor.withValues(
                  alpha: 0.3,
                ), // Tinted with planet color for better visibility
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(20),
                elevation: 15,
                side: BorderSide(
                  color: _countdownMode == mode
                      ? planetColor.withValues(alpha: 1.0)
                      : Colors.white.withValues(alpha: 0.8),
                  width: 3,
                ),
                shadowColor: planetColor.withValues(alpha: 0.8),
              ),
              onPressed: () {
                setState(() {
                  _countdownMode = mode;
                  _updateCountdown();
                });
              },
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.orbitron(
                  color: Colors.white,
                  fontSize: 16, // Increased font size for better readability
                  shadows: [
                    Shadow(
                      color: planetColor.withValues(alpha: 0.8),
                      blurRadius: 12,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOrbitingPlanets() {
    return AnimatedBuilder(
      animation: _orbitController,
      builder: (context, _) {
        return Stack(
          children: [
            _buildPlanet(60, 1.0, Colors.blueAccent, 120),
            _buildPlanet(40, 2.0, Colors.redAccent, 180),
            _buildPlanet(80, -1.0, Colors.purpleAccent, 240),
            _buildPlanet(50, 3.0, Colors.greenAccent, 100),
          ],
        );
      },
    );
  }

  Widget _buildPlanet(
    double radius,
    double speed,
    Color color,
    double orbitRadius,
  ) {
    final angle = _orbitController.value * 2 * pi * speed;
    return Positioned(
      left:
          (MediaQuery.of(context).size.width / 2) +
          cos(angle) * orbitRadius -
          radius / 2,
      top:
          (MediaQuery.of(context).size.height / 2) +
          sin(angle) * orbitRadius -
          radius / 2,
      child: Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: 0.5),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.7),
              blurRadius: 30,
              spreadRadius: 8,
            ),
          ],
        ),
      ),
    );
  }
}
