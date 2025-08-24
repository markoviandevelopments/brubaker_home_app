import 'package:flutter/material.dart';
import 'dart:math' as math;

class StarField extends StatefulWidget {
  final double opacity;
  final double offset; // Added offset parameter
  const StarField({super.key, this.opacity = 0.3, this.offset = 0.0});

  @override
  StarFieldState createState() => StarFieldState();
}

class StarFieldState extends State<StarField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _stars = [];
  final List<Color> _starColors = [];
  final int _starCount = 50;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();
    for (int i = 0; i < _starCount; i++) {
      _stars.add(
        Offset(
          (math.Random().nextDouble() * 1000) - 500,
          (math.Random().nextDouble() * 1000) - 500,
        ),
      );
      final random = math.Random().nextInt(3);
      _starColors.add(
        random == 0
            ? Colors.white
            : random == 1
            ? const Color(0xFF00FFFF).withValues(alpha: 0.5)
            : const Color(0xFFFFFF00).withValues(alpha: 0.5),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: _StarPainter(
            stars: _stars,
            colors: _starColors,
            animationValue: _controller.value,
            opacity: widget.opacity,
            offset: widget.offset, // Pass offset to painter
          ),
        );
      },
    );
  }
}

class _StarPainter extends CustomPainter {
  final List<Offset> stars;
  final List<Color> colors;
  final double animationValue;
  final double opacity;
  final double offset;

  _StarPainter({
    required this.stars,
    required this.colors,
    required this.animationValue,
    required this.opacity,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (int i = 0; i < stars.length; i++) {
      final paint = Paint()..color = colors[i].withValues(alpha: opacity);
      final scale = 1.0 + math.sin(animationValue * 2 * math.pi) * 0.3;
      final yPos =
          (stars[i].dy + offset) % size.height; // Apply offset to y-position
      canvas.drawCircle(
        Offset(stars[i].dx % size.width, yPos),
        1.5 * scale,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
