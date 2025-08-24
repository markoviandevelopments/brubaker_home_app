import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brubaker_homeapp/screens/star_field.dart';

class GamesScreen extends StatefulWidget {
  final Function(int) onGameSelected;

  const GamesScreen({super.key, required this.onGameSelected});

  @override
  GamesScreenState createState() => GamesScreenState();
}

class GamesScreenState extends State<GamesScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
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

  void _navigateToScreen(int index) {
    widget.onGameSelected(index);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final buttonWidth = (screenWidth * 0.7 > 280 ? 280.0 : screenWidth * 0.7)
        .toDouble();

    return Container(
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
          Positioned.fill(child: _NebulaBackground()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      child: Text(
                        'Galactic Games',
                        style: GoogleFonts.orbitron(
                          fontWeight: FontWeight.bold,
                          fontSize: 24,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                    _buildGameButton(
                      context,
                      title: 'Elements',
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF4B0082).withValues(alpha: 0.9),
                          Color(0xFF8A2BE2).withValues(alpha: 0.8),
                          Color(0xFF6A0DAD).withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        transform: GradientRotation(_controller.value * 0.25),
                      ),
                      glowColor: Colors.purpleAccent.withValues(alpha: 0.7),
                      onPressed: () => _navigateToScreen(1),
                      width: buttonWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildGameButton(
                      context,
                      title: 'Toad Jumper',
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF32CD32).withValues(alpha: 0.9),
                          Color(0xFF228B22).withValues(alpha: 0.8),
                          Color(0xFF006400).withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        transform: GradientRotation(_controller.value * 0.3),
                      ),
                      glowColor: Colors.greenAccent.withValues(alpha: 0.7),
                      onPressed: () => _navigateToScreen(2),
                      width: buttonWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildGameButton(
                      context,
                      title: 'Socket Game',
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF00FFFF).withValues(alpha: 0.9),
                          Color(0xFF00B7EB).withValues(alpha: 0.8),
                          Color(0xFF0077B6).withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        transform: GradientRotation(_controller.value * 0.1),
                      ),
                      glowColor: Colors.cyanAccent.withValues(alpha: 0.7),
                      onPressed: () => _navigateToScreen(3),
                      width: buttonWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildGameButton(
                      context,
                      title: 'Cosmic Name',
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFF4500).withValues(alpha: 0.9),
                          Color(0xFF8B0000).withValues(alpha: 0.8),
                          Color(0xFF4B0082).withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        transform: GradientRotation(_controller.value * 0.15),
                      ),
                      glowColor: Colors.redAccent.withValues(alpha: 0.7),
                      onPressed: () => _navigateToScreen(4),
                      width: buttonWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildGameButton(
                      context,
                      title: 'Minesweeper',
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFFFF00).withValues(alpha: 0.9),
                          Color(0xFFFFD700).withValues(alpha: 0.8),
                          Color(0xFFCCAC00).withValues(alpha: 0.7),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        transform: GradientRotation(_controller.value * 0.2),
                      ),
                      glowColor: Colors.yellowAccent.withValues(alpha: 0.7),
                      onPressed: () => _navigateToScreen(5),
                      width: buttonWidth,
                    ),
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
    required LinearGradient gradient,
    required Color glowColor,
    required VoidCallback onPressed,
    required double width,
  }) {
    return GestureDetector(
      onTapDown: (_) {
        if (mounted) {
          setState(() => _scale = 0.97);
        }
      },
      onTapUp: (_) {
        if (mounted) {
          setState(() => _scale = 1.0);
          onPressed();
        }
      },
      onTapCancel: () {
        if (mounted) {
          setState(() => _scale = 1.0);
        }
      },
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
                  gradient: gradient,
                  boxShadow: [
                    BoxShadow(
                      color: glowColor,
                      spreadRadius: 6,
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.6),
                      spreadRadius: -4,
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                  border: Border.all(
                    color: glowColor.withValues(alpha: 0.9),
                    width: 3,
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withValues(alpha: 0.5),
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
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: glowColor.withValues(alpha: 0.9),
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
}

class _NebulaBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _NebulaPainter(), child: Container());
  }
}

class _NebulaPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.purple.withValues(alpha: 0.3),
          Colors.blue.withValues(alpha: 0.2),
          Colors.transparent,
        ],
        center: Alignment(0.3, 0.4),
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
      paint..color = Colors.purple.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
