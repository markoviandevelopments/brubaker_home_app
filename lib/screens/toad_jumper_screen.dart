import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart' as animateDo;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:io' show Platform;
import 'package:brubaker_homeapp/screens/star_field.dart';

class ToadJumperScreen extends StatefulWidget {
  final Function(int) onGameSelected;

  const ToadJumperScreen({super.key, required this.onGameSelected});

  @override
  _ToadJumperScreenState createState() => _ToadJumperScreenState();
}

class _ToadJumperScreenState extends State<ToadJumperScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.stop();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Positioned.fill(child: StarField(opacity: 0.2)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white70,
                          size: 30,
                        ),
                        onPressed: () => widget.onGameSelected(0),
                      ),
                      Text(
                        'Toad Jumper',
                        style: GoogleFonts.orbitron(
                          color: Colors.white70,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 30),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 80.0),
                    child: ToadJumperGame(
                      controller: _controller,
                      onGameSelected: widget.onGameSelected,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ToadJumperGame extends StatefulWidget {
  final AnimationController controller;
  final Function(int) onGameSelected;

  const ToadJumperGame({
    super.key,
    required this.controller,
    required this.onGameSelected,
  });

  @override
  _ToadJumperGameState createState() => _ToadJumperGameState();
}

class _ToadJumperGameState extends State<ToadJumperGame> {
  double toadX = 0;
  double toadY = 0;
  double velocityY = 0;
  final double gravity = 1000;
  final double jumpSpeed = -600;
  final double horizontalSpeed = 200;
  List<Rect> platforms = [];
  int score = 0;
  double worldHeight = 0;
  final math.Random random = math.Random();
  double bgOffset1 = 0;
  double bgOffset2 = 0;
  double bgSpeed1 = 20;
  double bgSpeed2 = 30;
  bool isJumping = false;
  bool isGameOver = false;
  AccelerometerEvent? lastAccelerometerEvent;
  final FocusNode _focusNode = FocusNode();
  ui.Image? toadImage;
  bool isImageLoading = true;
  double animationPhase = 0;
  final List<Offset> particles = [];
  final List<double> particleAges = [];
  Size? screenSize;
  double? bottomPadding;
  bool justLanded = false;
  Color bgColorTop = const Color(0xFF0A0A1E);
  Color bgColorBottom = const Color(0xFF1A1A3A);
  Color platformColorStart = Colors.grey.shade300;
  Color platformColorEnd = const Color(0xFF00FFD1);
  double starOpacity = 0.5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (screenSize == null) {
      screenSize = MediaQuery.of(context).size;
      bottomPadding = MediaQuery.of(context).padding.bottom;
    }
    if (toadImage == null && isImageLoading) {
      toadX = screenSize!.width / 2 - 30;
      toadY = screenSize!.height - 220 - (bottomPadding ?? 0);
      spawnInitialPlatforms();
      _loadImage('assets/images/toad.png')
          .then((image) {
            if (mounted) {
              setState(() {
                toadImage = image;
                isImageLoading = false;
              });
            }
          })
          .catchError((e) {
            if (mounted) {
              setState(() {
                toadImage = null;
                isImageLoading = false;
              });
            }
          });
    }
    if (!Platform.isLinux) {
      accelerometerEvents.listen((AccelerometerEvent event) {
        if (mounted) {
          setState(() {
            lastAccelerometerEvent = event;
          });
        }
      });
    }
    widget.controller.addListener(() {
      if (!isGameOver && mounted) {
        const fixedDt = 1 / 60;
        updateGame(fixedDt);
        animationPhase += fixedDt;
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    widget.controller.removeListener(() {});
    super.dispose();
  }

  void spawnInitialPlatforms() {
    if (screenSize == null || bottomPadding == null) return;
    platforms.clear();
    platforms.add(
      Rect.fromLTWH(toadX, screenSize!.height - 160 - bottomPadding!, 100, 20),
    );
    for (int i = 1; i < 10; i++) {
      platforms.add(
        Rect.fromLTWH(
          random.nextDouble() * (screenSize!.width - 100),
          screenSize!.height - 160 - bottomPadding! - i * 120,
          100,
          20,
        ),
      );
    }
  }

  void resetGame() {
    if (!mounted) return;
    setState(() {
      score = 0;
      worldHeight = 0;
      velocityY = 0;
      isJumping = false;
      justLanded = false;
      isGameOver = false;
      animationPhase = 0;
      particles.clear();
      particleAges.clear();
      if (screenSize != null) {
        toadX = screenSize!.width / 2 - 30;
        toadY = screenSize!.height - 220 - (bottomPadding ?? 0);
        platforms.clear();
        spawnInitialPlatforms();
      }
      bgOffset1 = 0;
      bgOffset2 = 0;
      bgSpeed1 = 20;
      bgSpeed2 = 30;
      bgColorTop = const Color(0xFF0A0A1E);
      bgColorBottom = const Color(0xFF1A1A3A);
      platformColorStart = Colors.grey.shade300;
      platformColorEnd = const Color(0xFF00FFD1);
      starOpacity = 0.5;
    });
  }

  bool isOnPlatform() {
    final toadRect = Rect.fromLTWH(toadX, toadY, 60, 60);
    for (var platform in platforms) {
      if (toadRect.overlaps(platform)) {
        final overlap = platform.top - (toadY + 60);
        if (overlap >= -30 && overlap <= 5) {
          return true;
        }
      }
    }
    return false;
  }

  void updateGame(double dt) {
    if (!mounted || screenSize == null) return;
    setState(() {
      if (isJumping || !isOnPlatform()) {
        velocityY += gravity * dt;
        toadY += velocityY * dt;
        if (isJumping && velocityY < 0) {
          for (int i = 0; i < 2; i++) {
            particles.add(Offset(toadX + 30, toadY + 60));
            particleAges.add(0);
          }
        }
        justLanded = false;
      }

      if (toadY > screenSize!.height + 100) {
        isGameOver = true;
        return;
      }

      final toadRect = Rect.fromLTWH(toadX, toadY, 60, 60);
      for (var platform in platforms) {
        if (toadRect.overlaps(platform) && velocityY >= 0) {
          final overlap = platform.top - (toadY + 60);
          if (overlap >= -30 && overlap <= 5) {
            velocityY = 0;
            if (isJumping) {
              justLanded = true;
            }
            isJumping = false;
            toadY = platform.top - 60;
            if (justLanded && score < 1000) {
              score++;
              justLanded = false;
            }
          }
        }
      }

      if (toadY < screenSize!.height / 3) {
        final dy = screenSize!.height / 3 - toadY;
        toadY = screenSize!.height / 3;
        for (int i = 0; i < platforms.length; i++) {
          platforms[i] = platforms[i].translate(0, dy);
        }
        worldHeight += dy;

        while (platforms.isNotEmpty && platforms.last.top > -200) {
          final newY = platforms.last.top - (120 + random.nextDouble() * 80);
          platforms.add(
            Rect.fromLTWH(
              random.nextDouble() * (screenSize!.width - 100),
              newY,
              100,
              20,
            ),
          );
        }

        platforms.removeWhere((p) => p.top > screenSize!.height + 100);
      }

      bgOffset1 += bgSpeed1 * dt;
      bgOffset2 += bgSpeed2 * dt;
      if (bgOffset1 >= screenSize!.height) bgOffset1 -= screenSize!.height * 2;
      if (bgOffset2 >= screenSize!.height) bgOffset2 -= screenSize!.height * 2;

      if (!Platform.isLinux && lastAccelerometerEvent != null) {
        final x = lastAccelerometerEvent!.x;
        if (x.abs() > 2.0) {
          toadX -= x * horizontalSpeed * dt * 0.1;
          if (toadX < 0) toadX = 0;
          if (toadX > screenSize!.width - 60) toadX = screenSize!.width - 60;
        }
      }

      if (score % 20 == 0 && score > 0) {
        updateBackgroundProgress();
      }

      for (int i = particleAges.length - 1; i >= 0; i--) {
        particleAges[i] += dt;
        if (particleAges[i] > 0.5) {
          particles.removeAt(i);
          particleAges.removeAt(i);
        }
      }
    });
  }

  void updateBackgroundProgress() {
    final level = (score / 20).floor() + 1;
    bgSpeed1 += 2;
    bgSpeed2 += 3;

    final hue = (level * 5.0) % 360;
    final saturation = 0.7 + math.sin(level * 0.2) * 0.2;
    final value = 0.2 + math.cos(level * 0.15) * 0.1;
    bgColorTop = HSVColor.fromAHSV(1.0, hue, saturation, value).toColor();
    bgColorBottom = HSVColor.fromAHSV(
      1.0,
      (hue + 30) % 360,
      saturation * 0.8,
      value * 1.2,
    ).toColor();

    final platformHue = (hue + random.nextDouble() * 40 - 20) % 360;
    platformColorStart = HSVColor.fromAHSV(
      1.0,
      platformHue,
      0.6,
      0.7,
    ).toColor();
    platformColorEnd = HSVColor.fromAHSV(
      1.0,
      (platformHue + 20) % 360,
      0.8,
      0.9,
    ).toColor();

    starOpacity = 0.4 + math.sin(level * 0.05) * 0.15;
  }

  @override
  Widget build(BuildContext context) {
    screenSize ??= MediaQuery.of(context).size;
    return RawKeyboardListener(
      focusNode: _focusNode,
      autofocus: true,
      onKey: (RawKeyEvent event) {
        if (event is RawKeyDownEvent && !isGameOver) {
          if (event.logicalKey == LogicalKeyboardKey.space && !isJumping) {
            setState(() {
              velocityY = jumpSpeed;
              isJumping = true;
            });
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            setState(() {
              toadX -= horizontalSpeed * (1 / 60);
              if (toadX < 0) toadX = 0;
            });
          }
          if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            setState(() {
              toadX += horizontalSpeed * (1 / 60);
              if (toadX > screenSize!.width - 60)
                toadX = screenSize!.width - 60;
            });
          }
        }
      },
      child: GestureDetector(
        onTap: () {
          if (!isJumping && !isGameOver) {
            setState(() {
              velocityY = jumpSpeed;
              isJumping = true;
            });
          }
        },
        child: Stack(
          children: [
            Positioned(
              top: bgOffset1,
              child: SizedBox(
                width: screenSize!.width,
                height: screenSize!.height * 2,
                child: StarField(opacity: starOpacity, offset: bgOffset1),
              ),
            ),
            if (!isImageLoading && toadImage != null)
              CustomPaint(
                size: screenSize!,
                painter: ToadJumperPainter(
                  toadX: toadX,
                  toadY: toadY,
                  platforms: platforms,
                  bgOffset1: bgOffset1,
                  bgOffset2: bgOffset2,
                  score: score,
                  toadImage: toadImage!,
                  animationPhase: animationPhase,
                  particles: particles,
                  particleAges: particleAges,
                  bgColorTop: bgColorTop,
                  bgColorBottom: bgColorBottom,
                  platformColorStart: platformColorStart,
                  platformColorEnd: platformColorEnd,
                ),
              )
            else
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF00FFD1)),
                    const SizedBox(height: 16),
                    Text(
                      'Loading Toad Jumper...',
                      style: GoogleFonts.orbitron(
                        color: Colors.white70,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            if (isGameOver)
              animateDo.BounceInDown(
                duration: const Duration(milliseconds: 600),
                child: Center(
                  child: ClipRect(
                    child: BackdropFilter(
                      filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        margin: const EdgeInsets.symmetric(horizontal: 24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A0A1E).withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFFF4500),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFF4500).withOpacity(0.2),
                              blurRadius: 8,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            animateDo.ShakeX(
                              duration: const Duration(milliseconds: 800),
                              child: Text(
                                'Game Over',
                                style: GoogleFonts.orbitron(
                                  fontSize: 32,
                                  color: const Color(0xFFFF4500),
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withOpacity(0.5),
                                      blurRadius: 6,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Score: $score',
                              style: GoogleFonts.orbitron(
                                fontSize: 24,
                                color: const Color(0xFF00FFD1),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 16,
                              children: [
                                ElevatedButton(
                                  onPressed: resetGame,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                      0xFF00FFD1,
                                    ).withOpacity(0.3),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: const Color(
                                          0xFF00FFD1,
                                        ).withOpacity(0.5),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 24,
                                    ),
                                    elevation: 8,
                                  ),
                                  child: Text(
                                    'Restart',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 18,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                ElevatedButton(
                                  onPressed: () => widget.onGameSelected(0),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white.withOpacity(
                                      0.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 24,
                                    ),
                                    elevation: 8,
                                  ),
                                  child: Text(
                                    'Back to Games',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 18,
                                      color: Colors.white70,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<ui.Image> _loadImage(String asset) async {
    try {
      final data = await DefaultAssetBundle.of(context).load(asset);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      return frame.image;
    } catch (e) {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      canvas.drawRect(
        const Rect.fromLTWH(0, 0, 60, 60),
        Paint()..color = const Color(0xFF00FFD1),
      );
      final picture = recorder.endRecording();
      return await picture.toImage(60, 60);
    }
  }
}

class ToadJumperPainter extends CustomPainter {
  final double toadX;
  final double toadY;
  final List<Rect> platforms;
  final double bgOffset1;
  final double bgOffset2;
  final int score;
  final ui.Image toadImage;
  final double animationPhase;
  final List<Offset> particles;
  final List<double> particleAges;
  final Color bgColorTop;
  final Color bgColorBottom;
  final Color platformColorStart;
  final Color platformColorEnd;

  ToadJumperPainter({
    required this.toadX,
    required this.toadY,
    required this.platforms,
    required this.bgOffset1,
    required this.bgOffset2,
    required this.score,
    required this.toadImage,
    required this.animationPhase,
    required this.particles,
    required this.particleAges,
    required this.bgColorTop,
    required this.bgColorBottom,
    required this.platformColorStart,
    required this.platformColorEnd,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()
      ..shader = LinearGradient(
        colors: [bgColorTop.withOpacity(0.2), bgColorBottom.withOpacity(0.2)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, bgOffset2, size.width, size.height))
      ..blendMode = BlendMode.overlay;
    canvas.drawRect(
      Rect.fromLTWH(0, bgOffset2, size.width, size.height),
      bgPaint,
    );
    canvas.drawRect(
      Rect.fromLTWH(0, bgOffset2 + size.height, size.width, size.height),
      bgPaint,
    );

    final cityPaint = Paint()..color = Colors.black.withOpacity(0.3);
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height)
        ..lineTo(0, size.height - 50)
        ..lineTo(size.width / 4, size.height - 100)
        ..lineTo(size.width / 2, size.height - 80)
        ..lineTo(3 * size.width / 4, size.height - 120)
        ..lineTo(size.width, size.height - 60)
        ..lineTo(size.width, size.height)
        ..close(),
      cityPaint,
    );

    final gridPaint = Paint()
      ..color = const Color(0xFF00FFD1).withOpacity(0.1)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;
    for (double y = bgOffset2 % 100; y < size.height; y += 100) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (double x = 0; x < size.width; x += 100) {
      canvas.drawLine(
        Offset(x, bgOffset2),
        Offset(x, bgOffset2 + size.height),
        gridPaint,
      );
    }

    final platformPaint = Paint()
      ..shader = LinearGradient(
        colors: [platformColorStart, platformColorEnd],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, 100, 20));
    final platformBorderPaint = Paint()
      ..color = platformColorEnd.withOpacity(
        0.7 + 0.3 * math.sin(animationPhase * 2),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    final scanPaint = Paint()..color = const Color(0xFFFF4500).withOpacity(0.5);
    for (var platform in platforms) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(platform, const Radius.circular(5)),
        platformPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(platform, const Radius.circular(5)),
        platformBorderPaint,
      );
      final scanX =
          platform.left + (platform.width * ((animationPhase * 2) % 1));
      canvas.drawLine(
        Offset(scanX, platform.top),
        Offset(scanX, platform.bottom),
        scanPaint,
      );
    }

    for (int i = 0; i < particles.length; i++) {
      final opacity = 1.0 - (particleAges[i] / 0.5);
      final paint = Paint()
        ..color = const Color(0xFF00FFD1).withOpacity(opacity);
      canvas.drawCircle(particles[i], 2, paint);
    }

    final glowPaint = Paint()
      ..color = const Color(
        0xFF00FFD1,
      ).withOpacity(0.5 + 0.2 * math.sin(animationPhase * 2))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(toadX + 30, toadY + 30), 40, glowPaint);

    canvas.drawImageRect(
      toadImage,
      Rect.fromLTWH(
        0,
        0,
        toadImage.width.toDouble(),
        toadImage.height.toDouble(),
      ),
      Rect.fromLTWH(toadX, toadY, 60, 60),
      Paint(),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: 'Score: $score',
        style: GoogleFonts.orbitron(
          color: const Color(0xFF00FFD1),
          fontSize: 24,
          shadows: [
            Shadow(
              color: const Color(0xFFFF4500).withOpacity(0.6),
              blurRadius: 6,
            ),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
  }

  @override
  bool shouldRepaint(covariant ToadJumperPainter oldDelegate) => true;
}
