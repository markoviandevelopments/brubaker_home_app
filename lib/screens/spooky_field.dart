import 'package:flutter/material.dart';
import 'dart:math' as math;

class SpookyField extends StatefulWidget {
  const SpookyField({super.key});

  @override
  _SpookyFieldState createState() => _SpookyFieldState();
}

class _SpookyFieldState extends State<SpookyField>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12), // Longer cycle for pauses
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: CustomPaint(
        size: Size.infinite,
        painter: DrearySkyPainter(_controller),
      ),
    );
  }
}

class DrearySkyPainter extends CustomPainter {
  final AnimationController controller;

  DrearySkyPainter(this.controller) : super(repaint: controller);

  @override
  void paint(Canvas canvas, Size size) {
    // Swirling dark sky gradient
    final skyGradient = RadialGradient(
      center: Alignment(0.0, 0.0),
      radius: 1.8,
      colors: [
        const Color(0xFF1A1C1E), // Very dark gray
        const Color(0xFF2C2F33).withOpacity(0.9), // Stormy gray
        const Color(0xFF1F252A), // Dark swirling tint
      ],
      stops: [0.0, 0.7, 1.0],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    final skyPaint = Paint()..shader = skyGradient;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), skyPaint);

    // Stars poking through clouds
    final starPaint = Paint()
      ..color = const Color(0xFFFFFFFF).withOpacity(0.7)
      ..style = PaintingStyle.fill;
    final random = math.Random(456);
    const starCount = 50;

    for (int i = 0; i < starCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.6;
      final opacity =
          0.4 + math.sin(controller.value * math.pi * 2 + i * 0.3) * 0.3;
      final radius = random.nextDouble() * 1.5 + 0.5;

      canvas.drawCircle(
        Offset(x, y),
        radius,
        starPaint..color = starPaint.color.withOpacity(opacity),
      );
    }

    // Swirling stormy clouds
    final cloudPaint = Paint()
      ..color = const Color(0xFF2C2F33).withOpacity(0.5)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);
    const cloudCount = 20;

    for (int i = 0; i < cloudCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.7;
      final offset = math.sin(controller.value * math.pi * 2 + i * 0.4) * 30;
      final opacity =
          0.3 + math.sin(controller.value * math.pi * 2 + i * 0.5) * 0.2;
      final scale = 1.2 + math.sin(controller.value * math.pi * 2 + i) * 0.4;

      final cloudPath = Path();
      final center = Offset(x + offset, y);
      final cloudWidth = 60 * scale;
      final cloudHeight = 25 * scale;

      cloudPath
        ..moveTo(center.dx - cloudWidth, center.dy)
        ..quadraticBezierTo(
          center.dx - cloudWidth / 2,
          center.dy - cloudHeight,
          center.dx,
          center.dy - cloudHeight / 2,
        )
        ..quadraticBezierTo(
          center.dx + cloudWidth / 2,
          center.dy - cloudHeight,
          center.dx + cloudWidth,
          center.dy,
        )
        ..quadraticBezierTo(
          center.dx,
          center.dy + cloudHeight / 2,
          center.dx - cloudWidth,
          center.dy,
        )
        ..close();

      canvas.drawPath(
        cloudPath,
        cloudPaint..color = cloudPaint.color.withOpacity(opacity),
      );
    }

    // Vertical lightning strikes with branching
    final lightningPaint = Paint()
      ..color = const Color(0xFFDDEEFF).withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;
    final lightningRandom = math.Random();
    final lightningFlash = (math.sin(controller.value * math.pi * 4) + 1) / 2;

    if (lightningFlash > 0.98) {
      // Very high threshold for infrequent strikes
      // Decide if it's one or two strikes
      final strikeCount = lightningRandom.nextDouble() < 0.5 ? 1 : 2;

      for (int i = 0; i < strikeCount; i++) {
        // Main lightning path
        final startX = lightningRandom.nextDouble() * size.width;
        const startY = 0.0;
        final endY = size.height;

        final mainPath = Path();
        mainPath.moveTo(startX, startY);
        double currentY = startY;
        double currentX = startX;

        while (currentY < endY) {
          final segmentLength = lightningRandom.nextDouble() * 30 + 20;
          final offsetX = lightningRandom.nextDouble() * 60 - 30;
          currentX += offsetX;
          currentY += segmentLength;
          mainPath.lineTo(currentX, currentY);

          // Add occasional branch
          if (lightningRandom.nextDouble() < 0.4 && currentY < endY * 0.8) {
            final branchPath = Path();
            branchPath.moveTo(currentX, currentY);
            double branchX = currentX;
            double branchY = currentY;
            final branchLength = lightningRandom.nextDouble() * 60 + 40;
            final relativeAngle =
                lightningRandom.nextDouble() * (math.pi / 2) - (math.pi / 4);

            branchX += branchLength * math.sin(relativeAngle);
            branchY += branchLength * math.cos(relativeAngle);
            branchPath.lineTo(branchX, branchY);

            canvas.drawPath(
              branchPath,
              lightningPaint
                ..color = lightningPaint.color.withOpacity(
                  lightningFlash * 0.7,
                ),
            );
          }
        }

        canvas.drawPath(
          mainPath,
          lightningPaint
            ..color = lightningPaint.color.withOpacity(lightningFlash * 0.9),
        );

        // Slight delay effect for second strike
        if (strikeCount > 1) {
          // Small delay for back-to-back effect
          final delayFlash =
              (math.sin((controller.value + 0.05) * math.pi * 4) + 1) / 2;
          if (delayFlash > 0.98) {
            final secondStartX = lightningRandom.nextDouble() * size.width;
            final secondPath = Path();
            secondPath.moveTo(secondStartX, startY);
            currentY = startY;
            currentX = secondStartX;

            while (currentY < endY) {
              final segmentLength = lightningRandom.nextDouble() * 30 + 20;
              final offsetX = lightningRandom.nextDouble() * 60 - 30;
              currentX += offsetX;
              currentY += segmentLength;
              secondPath.lineTo(currentX, currentY);

              if (lightningRandom.nextDouble() < 0.4 && currentY < endY * 0.8) {
                final branchPath = Path();
                branchPath.moveTo(currentX, currentY);
                double branchX = currentX;
                double branchY = currentY;
                final branchLength = lightningRandom.nextDouble() * 60 + 40;
                final relativeAngle =
                    lightningRandom.nextDouble() * (math.pi / 2) -
                    (math.pi / 4);

                branchX += branchLength * math.sin(relativeAngle);
                branchY += branchLength * math.cos(relativeAngle);
                branchPath.lineTo(branchX, branchY);

                canvas.drawPath(
                  branchPath,
                  lightningPaint
                    ..color = lightningPaint.color.withOpacity(
                      delayFlash * 0.7,
                    ),
                );
              }
            }

            canvas.drawPath(
              secondPath,
              lightningPaint
                ..color = lightningPaint.color.withOpacity(delayFlash * 0.9),
            );
          }
        }
      }

      // Flash effect
      final flashPaint = Paint()
        ..color = const Color(0xFFFFFFFF).withOpacity(lightningFlash * 0.25);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), flashPaint);
    }

    // Subtle ghostly wisps
    final wispPaint = Paint()
      ..color = const Color(0xFFB2DFDB).withOpacity(0.25)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    const wispCount = 8;

    for (int i = 0; i < wispCount; i++) {
      final x = random.nextDouble() * size.width;
      final y = random.nextDouble() * size.height * 0.7 + size.height * 0.2;
      final offset = math.sin(controller.value * math.pi * 2 + i) * 8;
      final opacity =
          0.1 + math.sin(controller.value * math.pi * 2 + i * 0.5) * 0.15;
      final scale = 1 + math.sin(controller.value * math.pi * 2 + i) * 0.1;

      final wispPath = Path();
      final center = Offset(x + offset, y);
      final wispWidth = 5 * scale;
      final wispHeight = 12 * scale;

      wispPath
        ..moveTo(center.dx, center.dy - wispHeight)
        ..quadraticBezierTo(
          center.dx + wispWidth,
          center.dy,
          center.dx,
          center.dy + wispHeight,
        )
        ..quadraticBezierTo(
          center.dx - wispWidth,
          center.dy,
          center.dx,
          center.dy - wispHeight,
        )
        ..close();

      canvas.drawPath(
        wispPath,
        wispPaint..color = wispPaint.color.withOpacity(opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
