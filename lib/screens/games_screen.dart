// lib/screens/games_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import 'star_field.dart'; // Only the default background
import '../theme.dart';

class GamesScreen extends StatefulWidget {
  final Function(int) onGameSelected;

  const GamesScreen({super.key, required this.onGameSelected});

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;
  double _scale = 1.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToScreen(int index) => widget.onGameSelected(index);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = (screenWidth * 0.7 > 280 ? 280.0 : screenWidth * 0.7)
        .toDouble();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.scaffoldBackgroundColor, theme.colorScheme.surface],
        ),
      ),
      child: Stack(
        children: [
          // Default galactic starfield
          const Positioned.fill(child: StarField(opacity: 0.4)),

          // Consistent nebula glow using theme colors
          Positioned.fill(
            child: _NebulaBackground(
              primaryColor: theme.primaryColor,
              secondaryColor: theme.colorScheme.secondary,
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 20,
                      ),
                      child: Text(
                        'Galactic Games',
                        style: GoogleFonts.cinzelDecorative(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          color: theme.textTheme.bodyLarge?.color,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // ==== GAME BUTTONS (Cosmic Name removed) ====
                    _buildGameButton(
                      context,
                      title: 'Elements',
                      index: 0,
                      width: buttonWidth,
                      onPressed: () => _navigateToScreen(1),
                    ),
                    const SizedBox(height: 20),
                    _buildGameButton(
                      context,
                      title: 'Toad Jumper',
                      index: 1,
                      width: buttonWidth,
                      onPressed: () => _navigateToScreen(2),
                    ),
                    const SizedBox(height: 20),
                    _buildGameButton(
                      context,
                      title: 'Socket Game',
                      index: 2,
                      width: buttonWidth,
                      onPressed: () => _navigateToScreen(3),
                    ),
                    const SizedBox(height: 20),
                    _buildGameButton(
                      context,
                      title: 'Minesweeper',
                      index: 4,
                      width: buttonWidth,
                      onPressed: () => _navigateToScreen(5),
                    ),
                    const SizedBox(height: 20),
                    _buildGameButton(
                      context,
                      title: 'Codebreaker',
                      index: 5,
                      width: buttonWidth,
                      onPressed: () => _navigateToScreen(6),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameButton(
    BuildContext context, {
    required String title,
    required int index,
    required double width,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.97),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        onPressed();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scale * _pulseAnimation.value,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: Container(
                width: width,
                height: width * 0.3,
                decoration: BoxDecoration(
                  gradient: _buttonGradient(index),
                  boxShadow: [
                    BoxShadow(
                      color: _buttonGlow(index),
                      spreadRadius: 6,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: theme.scaffoldBackgroundColor.withOpacity(0.6),
                      spreadRadius: -4,
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                  border: Border.all(
                    color: _buttonGlow(index).withOpacity(0.9),
                    width: 3,
                  ),
                ),
                child: Stack(
                  children: [
                    // Subtle inner overlay
                    Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.textTheme.bodyLarge!.color!.withOpacity(0.5),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                      ),
                    ),
                    Center(
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.orbitron(
                          fontSize: width * 0.12,
                          fontWeight: FontWeight.w800,
                          color: theme.textTheme.bodyLarge!.color,
                          shadows: [
                            Shadow(
                              color: _buttonGlow(index).withOpacity(0.9),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  LinearGradient _buttonGradient(int index) {
    final colors = [
      Theme.of(context).primaryColor,
      Colors.greenAccent,
      Theme.of(context).colorScheme.secondary,
      Colors.redAccent,
      Colors.yellowAccent,
      Colors.blueAccent,
    ];
    final base = colors[index % colors.length];

    return LinearGradient(
      colors: [
        base.withOpacity(0.9),
        base.withOpacity(0.8),
        base.withOpacity(0.7),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      transform: GradientRotation(_controller.value * 0.25 + index * 0.05),
    );
  }

  Color _buttonGlow(int index) {
    final colors = [
      Theme.of(context).primaryColor,
      Colors.greenAccent,
      Theme.of(context).colorScheme.secondary,
      Colors.redAccent,
      Colors.yellowAccent,
      Colors.blueAccent,
    ];
    return colors[index % colors.length].withOpacity(0.7);
  }
}

// Reusable nebula background – identical to HomeScreen
class _NebulaBackground extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;

  const _NebulaBackground({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NebulaPainter(
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
      ),
    );
  }
}

class _NebulaPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _NebulaPainter({required this.primaryColor, required this.secondaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.3),
          secondaryColor.withOpacity(0.2),
          Colors.transparent,
        ],
        center: const Alignment(0.3, 0.4),
        radius: 0.6,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..blendMode = BlendMode.overlay;

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.4),
      size.width * 0.6,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.7),
      size.width * 0.5,
      paint..color = primaryColor.withOpacity(0.25),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
