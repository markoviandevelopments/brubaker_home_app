import 'package:flutter/material.dart';
import 'dart:math' as math;

class StarField extends StatefulWidget {
  const StarField({super.key});

  @override
  _StarFieldState createState() => _StarFieldState();
}

class _StarFieldState extends State<StarField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Offset> _stars = [];
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
        return CustomPaint(painter: _StarPainter(_stars, _controller.value));
      },
    );
  }
}

class _StarPainter extends CustomPainter {
  final List<Offset> stars;
  final double animationValue;

  _StarPainter(this.stars, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.3);
    for (var star in stars) {
      final scale = 1.0 + math.sin(animationValue * 2 * math.pi) * 0.3;
      canvas.drawCircle(
        Offset(star.dx % size.width, star.dy % size.height),
        1.5 * scale,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
