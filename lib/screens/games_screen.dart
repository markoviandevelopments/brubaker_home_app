import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brubaker_homeapp/screens/star_field.dart';

class GamesScreen extends StatefulWidget {
  final Function(int) onGameSelected; // Required to ensure navigation

  const GamesScreen({super.key, required this.onGameSelected});

  @override
  _GamesScreenState createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen>
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
    print('Navigating to screen with index: $index');
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
                          Color(0xFF4B0082),
                          Color(0xFF8A2BE2),
                          Color(0xFF6A0DAD),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        transform: GradientRotation(_controller.value * 0.25),
                      ),
                      glowColor: Colors.purpleAccent,
                      onPressed: () => _navigateToScreen(1),
                      width: buttonWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildGameButton(
                      context,
                      title: 'Toad Jumper',
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF32CD32),
                          Color(0xFF228B22),
                          Color(0xFF006400),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        transform: GradientRotation(_controller.value * 0.3),
                      ),
                      glowColor: Colors.greenAccent,
                      onPressed: () => _navigateToScreen(2),
                      width: buttonWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildGameButton(
                      context,
                      title: 'Socket Game',
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFF00FFFF),
                          Color(0xFF00B7EB),
                          Color(0xFF0077B6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        transform: GradientRotation(_controller.value * 0.1),
                      ),
                      glowColor: Colors.cyanAccent,
                      onPressed: () => _navigateToScreen(3),
                      width: buttonWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildGameButton(
                      context,
                      title: 'Silly Name',
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFF4500),
                          Color(0xFF8B0000),
                          Color(0xFF4B0082),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        transform: GradientRotation(_controller.value * 0.15),
                      ),
                      glowColor: Colors.redAccent,
                      onPressed: () => _navigateToScreen(4),
                      width: buttonWidth,
                    ),
                    const SizedBox(height: 20),
                    _buildGameButton(
                      context,
                      title: 'Minesweeper',
                      gradient: LinearGradient(
                        colors: [
                          Color(0xFFFFFF00),
                          Color(0xFFFFD700),
                          Color(0xFFCCAC00),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        transform: GradientRotation(_controller.value * 0.2),
                      ),
                      glowColor: Colors.yellowAccent,
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
          print('Button tapped: $title');
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
                      color: glowColor.withOpacity(0.7),
                      spreadRadius: 4,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(0.5),
                      spreadRadius: -3,
                      blurRadius: 8,
                      offset: const Offset(0, -3),
                    ),
                  ],
                  border: Border.all(
                    color: glowColor.withOpacity(0.9),
                    width: 2.5,
                  ),
                ),
                child: Stack(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(2.5),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.white.withOpacity(0.4),
                            Colors.transparent,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22.5),
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
                              color: glowColor.withOpacity(0.8),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
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
      ..shader = LinearGradient(
        colors: [
          Colors.purple.withOpacity(0.25),
          Colors.blue.withOpacity(0.15),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
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
      paint..color = Colors.purple.withOpacity(0.2),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
