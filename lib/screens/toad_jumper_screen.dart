import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart' as animate_do;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:io';
import 'package:brubaker_homeapp/screens/star_field.dart';
import 'package:brubaker_homeapp/screens/spooky_field.dart';
import 'package:provider/provider.dart';
import 'package:brubaker_homeapp/theme.dart';

class ToadJumperScreen extends StatefulWidget {
  final Function(int) onGameSelected;
  const ToadJumperScreen({super.key, required this.onGameSelected});
  @override
  ToadJumperScreenState createState() => ToadJumperScreenState();
}

class ToadJumperScreenState extends State<ToadJumperScreen>
    with TickerProviderStateMixin {
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
            Theme.of(context).colorScheme.surface.withOpacity(0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child:
                Theme.of(context).scaffoldBackgroundColor ==
                    const Color(0xFF1C2526)
                ? const SpookyField()
                : StarField(opacity: 0.3),
          ),
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
                        icon: Icon(
                          Icons.arrow_back,
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                          size: 30,
                        ),
                        onPressed: () => widget.onGameSelected(0),
                      ),
                      Text(
                        'Toad Jumper',
                        style: GoogleFonts.orbitron(
                          color: Theme.of(context).textTheme.bodyLarge!.color,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 30),
                    ],
                  ),
                ),
                Expanded(
                  child: ToadJumperGame(
                    controller: _controller,
                    onGameSelected: widget.onGameSelected,
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

class Pickup {
  double offsetX;
  double offsetY;
  Pickup(this.offsetX, this.offsetY);
}

class PlatformRect {
  Rect rect;
  double vx;
  Pickup? pickup;
  PlatformRect(this.rect, this.vx, {this.pickup});
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
  ToadJumperGameState createState() => ToadJumperGameState();
}

class ToadJumperGameState extends State<ToadJumperGame>
    with TickerProviderStateMixin {
  double toadX = 0;
  double toadY = 0;
  double velocityY = 0;
  final double gravity = 1000;
  final double jumpSpeed = -600;
  final double horizontalSpeed = 200;
  List<PlatformRect> platforms = [];
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
  late Color platformColor;
  double starOpacity = 0.5;
  late AnimationController _colorController;
  late Animation<Color> _colorAnimation;
  int lives = 3;
  int spawnLifeAfter = -1;
  int lastLevel = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final themeProvider = Provider.of<ThemeProvider>(context);
    bottomPadding = 0.0;
    platformColor =
        Theme.of(context).scaffoldBackgroundColor == const Color(0xFF1C2526)
        ? Colors.orange.shade300
        : Colors.grey.shade300;

    if (toadImage == null && isImageLoading) {
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
      accelerometerEventStream().listen((AccelerometerEvent event) {
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
        if (_colorController.isAnimating) {
          setState(() {});
        }
      }
    });
    _colorController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _colorAnimation = _colorController.drive(
      Tween<Color>(
        begin: platformColor,
        end:
            Theme.of(context).scaffoldBackgroundColor == const Color(0xFF1C2526)
            ? Colors.deepOrange.shade400
            : const Color(0xFF00FFD1),
      ).chain(CurveTween(curve: Curves.easeInOut)),
    );
    _colorAnimation.addListener(() {
      if (mounted) {
        setState(() {
          platformColor = _colorAnimation.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _colorController.dispose();
    widget.controller.removeListener(() {});
    super.dispose();
  }

  void spawnInitialPlatforms() {
    if (screenSize == null || bottomPadding == null) return;
    platforms.clear();
    double initialWidth = screenSize!.width;
    platforms.add(
      PlatformRect(
        Rect.fromLTWH(
          0,
          screenSize!.height - 20 - bottomPadding!,
          initialWidth,
          20,
        ),
        0,
      ),
    );
    for (int i = 1; i < 10; i++) {
      double pWidth = 100 - (worldHeight / 2000).clamp(0, 40);
      double left = random.nextDouble() * (screenSize!.width - pWidth);
      double vx = 0;
      if (random.nextDouble() > 0.8 - worldHeight / 10000) {
        vx =
            (random.nextDouble() * 2 - 1) *
            (50 + worldHeight / 5000).clamp(0, 200);
      }
      platforms.add(
        PlatformRect(
          Rect.fromLTWH(
            left,
            screenSize!.height - 20 - bottomPadding! - i * 120,
            pWidth,
            20,
          ),
          vx,
        ),
      );
    }
  }

  void resetGame() {
    if (!mounted) return;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
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
      lives = 3;
      spawnLifeAfter = -1;
      lastLevel = 0;
      if (screenSize != null) {
        toadX = screenSize!.width / 2 - 30;
        toadY = screenSize!.height - 60 - (bottomPadding ?? 0);
        platforms.clear();
        spawnInitialPlatforms();
      }
      bgOffset1 = 0;
      bgOffset2 = 0;
      bgSpeed1 = 20;
      bgSpeed2 = 30;
      platformColor =
          Theme.of(context).scaffoldBackgroundColor == const Color(0xFF1C2526)
          ? Colors.orange.shade300
          : Colors.grey.shade300;
      starOpacity = 0.5;
      _colorController.reset();
      _colorAnimation = _colorController.drive(
        Tween<Color>(
          begin: platformColor,
          end:
              Theme.of(context).scaffoldBackgroundColor ==
                  const Color(0xFF1C2526)
              ? Colors.deepOrange.shade400
              : const Color(0xFF00FFD1),
        ).chain(CurveTween(curve: Curves.easeInOut)),
      );
    });
  }

  bool isOnPlatform() {
    final toadRect = Rect.fromLTWH(toadX, toadY, 60, 60);
    for (var platform in platforms) {
      if (toadRect.overlaps(platform.rect)) {
        final overlap = platform.rect.top - (toadY + 60);
        if (overlap >= -30 && overlap <= 5) {
          return true;
        }
      }
    }
    return false;
  }

  void updateGame(double dt) {
    if (!mounted || screenSize == null || bottomPadding == null) return;
    setState(() {
      for (var platform in platforms) {
        platform.rect = platform.rect.translate(platform.vx * dt, 0);
        if (platform.rect.left < 0 || platform.rect.right > screenSize!.width) {
          platform.vx = -platform.vx;
        }
      }
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
      if (toadY > screenSize!.height - bottomPadding! + 120) {
        lives--;
        if (lives <= 0) {
          isGameOver = true;
        } else {
          spawnLifeAfter = 5 + random.nextInt(6);
          double maxTop = double.negativeInfinity;
          PlatformRect? bottomPlatform;
          for (var p in platforms) {
            if (p.rect.top > maxTop) {
              maxTop = p.rect.top;
              bottomPlatform = p;
            }
          }
          if (bottomPlatform != null) {
            toadX =
                bottomPlatform.rect.left + (bottomPlatform.rect.width - 60) / 2;
            toadY = bottomPlatform.rect.top - 60;
          } else {
            toadY = screenSize!.height - 60 - bottomPadding!;
            toadX = screenSize!.width / 2 - 30;
          }
          velocityY = 0;
          isJumping = false;
        }
      }
      final toadRect = Rect.fromLTWH(toadX, toadY, 60, 60);
      for (var platform in platforms) {
        if (toadRect.overlaps(platform.rect) && velocityY >= 0) {
          final overlap = platform.rect.top - (toadY + 60);
          if (overlap >= -30 && overlap <= 5) {
            velocityY = 0;
            if (isJumping) {
              justLanded = true;
            }
            isJumping = false;
            toadY = platform.rect.top - 60;
            if (justLanded) {
              score++;
              justLanded = false;
            }
          }
        }
        if (platform.pickup != null) {
          double px = platform.rect.left + platform.pickup!.offsetX;
          double py = platform.rect.top + platform.pickup!.offsetY;
          var lifeRect = Rect.fromLTWH(px, py, 20, 20);
          if (toadRect.overlaps(lifeRect)) {
            lives = math.min(3, lives + 1);
            platform.pickup = null;
          }
        }
      }
      if (toadY < screenSize!.height / 3) {
        final dy = screenSize!.height / 3 - toadY;
        toadY = screenSize!.height / 3;
        for (int i = 0; i < platforms.length; i++) {
          platforms[i].rect = platforms[i].rect.translate(0, dy);
        }
        worldHeight += dy;
        bgOffset1 += bgSpeed1 * dt;
        bgOffset2 += bgSpeed2 * dt;
        while (platforms.isNotEmpty && platforms.last.rect.top > -200) {
          final newY =
              platforms.last.rect.top - (120 + random.nextDouble() * 80);
          double pWidth = 100 - (worldHeight / 2000).clamp(0, 40);
          double left = random.nextDouble() * (screenSize!.width - pWidth);
          double vx = 0;
          if (random.nextDouble() > 0.8 - worldHeight / 10000) {
            vx =
                (random.nextDouble() * 2 - 1) *
                (50 + worldHeight / 5000).clamp(0, 200);
          }
          var newPlatform = PlatformRect(
            Rect.fromLTWH(left, newY, pWidth, 20),
            vx,
          );
          if (spawnLifeAfter > 0) {
            spawnLifeAfter--;
            if (spawnLifeAfter == 0) {
              newPlatform.pickup = Pickup(pWidth / 2 - 10, -20);
            }
          }
          platforms.add(newPlatform);
        }
        platforms.removeWhere(
          (p) => p.rect.top > screenSize!.height - bottomPadding! + 120,
        );
      }
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
      int currentLevel = (score / 20).floor();
      if (currentLevel > lastLevel) {
        lastLevel = currentLevel;
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final level = lastLevel + 1;
    bgSpeed1 += 2;
    bgSpeed2 += 3;
    final hue = (level * 5.0) % 360;
    starOpacity = 0.4 + math.sin(level * 0.05) * 0.15;
    _colorController.stop();
    _colorController.reset();
    _colorAnimation = _colorController.drive(
      Tween<Color>(
        begin: platformColor,
        end:
            Theme.of(context).scaffoldBackgroundColor == const Color(0xFF1C2526)
            ? Colors.deepOrange.shade400
            : HSVColor.fromAHSV(
                1.0,
                (hue + random.nextDouble() * 20 - 10) % 360,
                0.7,
                0.5,
              ).toColor(),
      ).chain(CurveTween(curve: Curves.easeInOut)),
    );
    _colorAnimation.addListener(() {
      if (mounted) {
        setState(() {
          platformColor = _colorAnimation.value;
        });
      }
    });
    _colorController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        if (screenSize == null) {
          screenSize = Size(constraints.maxWidth, constraints.maxHeight);
          toadX = screenSize!.width / 2 - 30;
          toadY = screenSize!.height - 60 - bottomPadding!;
          spawnInitialPlatforms();
        }
        return KeyboardListener(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: (KeyEvent event) {
            if (event is KeyDownEvent && !isGameOver) {
              if (event.logicalKey == LogicalKeyboardKey.space && !isJumping) {
                setState(() {
                  velocityY = jumpSpeed;
                  isJumping = true;
                });
              } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                setState(() {
                  toadX -= horizontalSpeed * (1 / 60);
                  if (toadX < 0) toadX = 0;
                });
              } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                setState(() {
                  toadX += horizontalSpeed * (1 / 60);
                  if (toadX > screenSize!.width - 60) {
                    toadX = screenSize!.width - 60;
                  }
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
                  left: 0,
                  child: SizedBox(
                    width: screenSize!.width,
                    height: screenSize!.height * 2,
                    child:
                        Theme.of(context).scaffoldBackgroundColor ==
                            const Color(0xFF1C2526)
                        ? SpookyField()
                        : StarField(opacity: starOpacity, offset: bgOffset1),
                  ),
                ),
                if (!isImageLoading && toadImage != null)
                  Positioned.fill(
                    child: CustomPaint(
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
                        bgColorTop: Theme.of(context).scaffoldBackgroundColor,
                        bgColorBottom: Theme.of(context).colorScheme.surface,
                        platformColor: platformColor,
                        lives: lives,
                      ),
                    ),
                  )
                else
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          color: Theme.of(context).primaryColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Loading Toad Jumper...',
                          style: GoogleFonts.orbitron(
                            color: Theme.of(context).textTheme.bodyLarge!.color,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isGameOver)
                  animate_do.BounceInDown(
                    duration: const Duration(milliseconds: 600),
                    child: Center(
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 400),
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).scaffoldBackgroundColor.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.2),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                animate_do.ShakeX(
                                  duration: const Duration(milliseconds: 800),
                                  child: Text(
                                    'Game Over',
                                    style: GoogleFonts.orbitron(
                                      fontSize: 28,
                                      color: Theme.of(context).primaryColor,
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
                                const SizedBox(height: 16),
                                Text(
                                  'Score: $score',
                                  style: GoogleFonts.orbitron(
                                    fontSize: 20,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.secondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 10,
                                  runSpacing: 10,
                                  children: [
                                    ElevatedButton(
                                      onPressed: resetGame,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).primaryColor.withOpacity(0.3),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          side: BorderSide(
                                            color: Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.5),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 16,
                                        ),
                                        elevation: 6,
                                      ),
                                      child: Text(
                                        'Restart',
                                        style: GoogleFonts.orbitron(
                                          fontSize: 14,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge!.color,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => widget.onGameSelected(0),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Theme.of(
                                          context,
                                        ).colorScheme.surface.withOpacity(0.2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          side: BorderSide(
                                            color: Theme.of(context)
                                                .textTheme
                                                .bodyLarge!
                                                .color!
                                                .withOpacity(0.3),
                                          ),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8,
                                          horizontal: 16,
                                        ),
                                        elevation: 6,
                                      ),
                                      child: Text(
                                        'Back to Games',
                                        style: GoogleFonts.orbitron(
                                          fontSize: 14,
                                          color: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge!.color,
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
      },
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
        Paint()..color = Theme.of(context).primaryColor,
      );
      final picture = recorder.endRecording();
      return await picture.toImage(60, 60);
    }
  }
}

class ToadJumperPainter extends CustomPainter {
  final double toadX;
  final double toadY;
  final List<PlatformRect> platforms;
  final double bgOffset1;
  final double bgOffset2;
  final int score;
  final ui.Image toadImage;
  final double animationPhase;
  final List<Offset> particles;
  final List<double> particleAges;
  final Color bgColorTop;
  final Color bgColorBottom;
  final Color platformColor;
  final int lives;

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
    required this.platformColor,
    required this.lives,
  });

  Path getHeartPath(double x, double y, double size) {
    Path path = Path()
      ..moveTo(x + size / 2, y + size / 5)
      ..cubicTo(
        x + 5 * size / 6,
        y,
        x + size,
        y + 2 * size / 5,
        x + size / 2,
        y + 3 * size / 5,
      )
      ..cubicTo(
        x,
        y + 2 * size / 5,
        x + size / 6,
        y,
        x + size / 2,
        y + size / 5,
      )
      ..close();
    return path;
  }

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
      ..color = bgColorBottom.withOpacity(0.1)
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
      ..color = platformColor.withOpacity(0.8)
      ..style = PaintingStyle.fill;
    final platformBorderPaint = Paint()
      ..color = platformColor.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    for (var platform in platforms) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(platform.rect, const Radius.circular(5)),
        platformPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(platform.rect, const Radius.circular(5)),
        platformBorderPaint,
      );
      if (platform.pickup != null) {
        double px = platform.rect.left + platform.pickup!.offsetX;
        double py = platform.rect.top + platform.pickup!.offsetY;
        canvas.drawPath(getHeartPath(px, py, 20), Paint()..color = Colors.red);
      }
    }
    for (int i = 0; i < particles.length; i++) {
      final opacity = 1.0 - (particleAges[i] / 0.5);
      final paint = Paint()..color = bgColorBottom.withOpacity(opacity);
      canvas.drawCircle(particles[i], 2, paint);
    }
    final glowPaint = Paint()
      ..color = bgColorBottom.withOpacity(
        0.5 + 0.2 * math.sin(animationPhase * 2),
      )
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
          color: bgColorBottom,
          fontSize: 24,
          shadows: [
            Shadow(color: bgColorBottom.withOpacity(0.6), blurRadius: 6),
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, const Offset(10, 10));
    double heartSize = 20;
    double startX = size.width - 10 - 3 * (heartSize + 5);
    for (int i = 0; i < 3; i++) {
      double hx = startX + i * (heartSize + 5);
      double hy = 10;
      Color hc = (i < lives) ? Colors.red : Colors.grey.withOpacity(0.5);
      var hpaint = Paint()..color = hc;
      canvas.drawPath(getHeartPath(hx, hy, heartSize), hpaint);
    }
  }

  @override
  bool shouldRepaint(covariant ToadJumperPainter oldDelegate) => true;
}
