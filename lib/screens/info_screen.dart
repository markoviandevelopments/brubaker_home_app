// lib/screens/info_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart' as animate_do;
import 'dart:async';
import 'dart:ui';
import 'dart:math' show pi, cos, sin;

import 'star_field.dart'; // Only the default starfield

class InfoScreen extends StatefulWidget {
  const InfoScreen({super.key});

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> with TickerProviderStateMixin {
  late final AnimationController _orbitController;
  late final AnimationController _glowController;

  // Cycling quirky messages
  late Timer _messageTimer;
  int _currentMessageIndex = 0;
  final List<String> _quirkyMessages = [
    "Currently orbiting Willoh at safe distance ❤️",
    "Starbase Brubaker: All systems nominal... and in love",
    "Nebula Brew reserves: Critical (need Thursday refill)",
    "Quantum entanglement with Preston: 100% stable",
    "Sonic toothbrush stealth mode: Engaged",
    "Lorax political economy debate scheduled for 2026",
    "Two bodies in gravitational harmony since 2024",
    "Stardust collection rate: Exceeding expectations",
    "Willoh's orbit: Perfectly elliptical, perfectly perfect",
    "Interstellar snacking protocols: Active and happy",
    "Distance to next hug: Classified (but worth it)",
    "Starbase status: Cozy, caffeinated, and crushing",
  ];

  @override
  void initState() {
    super.initState();

    // Cycle messages every 6 seconds
    _messageTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      setState(() {
        _currentMessageIndex =
            (_currentMessageIndex + 1) % _quirkyMessages.length;
      });
    });

    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _messageTimer.cancel();
    _orbitController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Info',
          style: GoogleFonts.orbitron(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            shadows: [
              Shadow(
                color: theme.primaryColor.withOpacity(0.5),
                blurRadius: 10,
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.scaffoldBackgroundColor, theme.colorScheme.surface],
          ),
        ),
        child: Stack(
          children: [
            // Galactic starfield background
            const Positioned.fill(child: StarField(opacity: 0.7)),

            // Orbiting planets
            Positioned.fill(child: _buildOrbitingPlanets()),

            // Main content
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  // Inside the Column in build() -> SafeArea -> Center -> Column
                  children: [
                    // Static title — no more spinning!
                    Text(
                      'Starbase Brubaker\nActive & Thriving',
                      style: GoogleFonts.orbitron(
                        color: theme.textTheme.bodyLarge!.color,
                        fontWeight: FontWeight.bold,
                        fontSize: 28,
                        shadows: [
                          Shadow(
                            color: theme.primaryColor.withOpacity(0.7),
                            blurRadius: 15,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 50),

                    // Quirky rotating message — still fades beautifully
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 800),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Text(
                        _quirkyMessages[_currentMessageIndex],
                        key: ValueKey<int>(_currentMessageIndex),
                        style: GoogleFonts.orbitron(
                          color: theme.textTheme.bodyLarge!.color,
                          fontSize: 24,
                          height: 1.4,
                          shadows: [
                            Shadow(
                              color: theme.primaryColor.withOpacity(0.6),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 80),
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
          backgroundColor: theme.scaffoldBackgroundColor,
          elevation: 10,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.primaryColor.withOpacity(0.8),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withOpacity(0.6),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Icon(
              Icons.info_outline,
              color: theme.primaryColor,
              size: 30,
            ),
          ),
          onPressed: () => _showHouseInfoDialog(context),
        ),
      ),
    );
  }

  Widget _buildOrbitingPlanets() {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: _orbitController,
      builder: (_, __) => Stack(
        children: [
          _buildPlanet(60, 1.0, theme.primaryColor, 120),
          _buildPlanet(40, 2.0, Colors.redAccent, 180),
          _buildPlanet(80, -1.0, theme.colorScheme.secondary, 240),
          _buildPlanet(50, 3.0, Colors.greenAccent, 100),
        ],
      ),
    );
  }

  Widget _buildPlanet(
    double radius,
    double speed,
    Color color,
    double orbitRadius,
  ) {
    final angle = _orbitController.value * 2 * pi * speed;
    final size = MediaQuery.of(context).size;
    return Positioned(
      left: size.width / 2 + cos(angle) * orbitRadius - radius / 2,
      top: size.height / 2 + sin(angle) * orbitRadius - radius / 2,
      child: Container(
        width: radius,
        height: radius,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withOpacity(0.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.7),
              blurRadius: 30,
              spreadRadius: 8,
            ),
          ],
        ),
      ),
    );
  }

  // === All your dialog methods below (unchanged and perfect) ===

  void _showHouseInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => animate_do.FadeIn(
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
                      Theme.of(context).primaryColor.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                    radius: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).primaryColor.withOpacity(0.3),
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
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        shadows: [
                          Shadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.5),
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
                style: GoogleFonts.orbitron(
                  color: Theme.of(context).primaryColor,
                ),
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
        leading: Icon(icon, color: Theme.of(context).primaryColor),
        title: Text(
          title,
          style: GoogleFonts.orbitron(
            color: Theme.of(context).textTheme.bodyLarge!.color,
            fontSize: 16,
            shadows: [
              Shadow(
                color: Theme.of(context).primaryColor.withOpacity(0.3),
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
    late final Widget content;

    if (title == 'Starbase Rules') {
      content = Text(
        '1. No sonic tooth-brushing near Willoh’s orbit.\n'
        '2. Maintain stealth chewing protocols.\n'
        '3. See rule 1.\n'
        '4. Lorax discussions must explore its interstellar political economy.',
        style: GoogleFonts.orbitron(
          color: Theme.of(context).textTheme.bodyLarge!.color,
          fontSize: 14,
        ),
      );
    } else if (title == 'Nebula Brew Station') {
      content = Text(
        'Grind cosmic beans to a pulsar texture, compress into a pod, and activate the brew core.',
        style: GoogleFonts.orbitron(
          color: Theme.of(context).textTheme.bodyLarge!.color,
          fontSize: 14,
        ),
      );
    } else if (title == 'Quantum Network') {
      content = Text(
        'Network: BrubakerNebula\nPasscode: Star\$ton01',
        style: GoogleFonts.orbitron(
          color: Theme.of(context).textTheme.bodyLarge!.color,
          fontSize: 14,
        ),
      );
    } else {
      content = Text(
        'No data in this sector.',
        style: GoogleFonts.orbitron(
          color: Theme.of(context).textTheme.bodyLarge!.color,
          fontSize: 14,
        ),
      );
    }

    showDialog(
      context: context,
      builder: (_) => animate_do.ZoomIn(
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
                      Theme.of(context).primaryColor.withOpacity(0.3),
                      Colors.black.withOpacity(0.7),
                    ],
                    radius: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Theme.of(context).primaryColor.withOpacity(0.5),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.orbitron(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        shadows: [
                          Shadow(
                            color: Theme.of(
                              context,
                            ).primaryColor.withOpacity(0.5),
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
                style: GoogleFonts.orbitron(
                  color: Theme.of(context).primaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
