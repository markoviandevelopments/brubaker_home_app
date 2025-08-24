import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart' as animate_do;
import 'dart:math';
import 'dart:async';
import 'dart:ui';

enum Direction { none, up, down, left, right }

class SocketGameScreen extends StatefulWidget {
  final Function(int)? onGameSelected;

  const SocketGameScreen({super.key, this.onGameSelected});

  @override
  SocketGameScreenState createState() => SocketGameScreenState();
}

class SocketGameScreenState extends State<SocketGameScreen>
    with SingleTickerProviderStateMixin {
  int currentRow = 0;
  int currentCol = 0;
  int score = 0;
  int level = 1;
  int cycle = 0;
  int movesLeft = 100;
  int timeLeft = 35;
  final Random random = Random();
  late List<List<bool>> hasCollectible;
  late List<List<bool>> hasObstacle;
  late List<List<Color>> gridColors;
  int? targetRow, targetCol;
  Timer? _moveTimer;
  Timer? _hazardTimer;
  Timer? _countdownTimer;
  bool isGameOver = false;
  Offset _joystickDelta = Offset.zero;
  final double _joystickRadius = 60.0;
  final double _moveThreshold = 40.0;
  Direction _currentMoveDirection = Direction.none;

  @override
  void initState() {
    super.initState();
    _initializeLevel();
  }

  void _initializeLevel() {
    if (!mounted) return;
    setState(() {
      hasCollectible = List.generate(
        10,
        (_) => List.generate(10, (_) => false),
      );
      hasObstacle = List.generate(10, (_) => List.generate(10, (_) => false));
      gridColors = List.generate(
        10,
        (_) => List.generate(10, (_) => _getGridColor()),
      );
      currentRow = 0;
      currentCol = 0;
      movesLeft = level == 2 ? (30 - cycle * 2).clamp(15, 30) : -1;
      timeLeft = level == 3 ? (35 - cycle * 2).clamp(20, 35) : -1;
      isGameOver = false;

      if (level == 1) {
        _spawnCollectibles(3 + cycle);
      } else if (level == 2) {
        _spawnCollectibles(3 + cycle);
        _spawnObstacles(3 + cycle);
      } else if (level == 3) {
        _spawnTarget();
        _spawnObstacles(3 + cycle);
        _startHazardTimer();
        _startCountdownTimer();
      }
    });
  }

  Color _getGridColor() {
    if (level == 1) {
      return const Color(
        0xFF0A0A1E,
      ).withValues(alpha: 0.2 + random.nextDouble() * 0.1);
    } else if (level == 2) {
      return const Color(
        0xFF1A1A3A,
      ).withValues(alpha: 0.3 + random.nextDouble() * 0.1);
    } else {
      return const Color(
        0xFF2A0A4A,
      ).withValues(alpha: 0.4 + random.nextDouble() * 0.1);
    }
  }

  void _spawnCollectibles(int count) {
    for (int i = 0; i < count; i++) {
      int x = random.nextInt(10);
      int y = random.nextInt(10);
      if (!hasCollectible[x][y] &&
          !hasObstacle[x][y] &&
          !(x == currentRow && y == currentCol)) {
        hasCollectible[x][y] = true;
      }
    }
  }

  void _spawnObstacles(int count) {
    for (int i = 0; i < count.clamp(0, 20); i++) {
      int x = random.nextInt(10);
      int y = random.nextInt(10);
      if (!hasCollectible[x][y] &&
          !hasObstacle[x][y] &&
          !(x == currentRow && y == currentCol)) {
        hasObstacle[x][y] = true;
      }
    }
  }

  void _spawnTarget() {
    targetRow = random.nextInt(10);
    targetCol = random.nextInt(10);
    while (targetRow == currentRow && targetCol == currentCol) {
      targetRow = random.nextInt(10);
      targetCol = random.nextInt(10);
    }
  }

  void _startHazardTimer() {
    _hazardTimer?.cancel();
    _hazardTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        List<List<bool>> newObstacles = List.generate(
          10,
          (_) => List.generate(10, (_) => false),
        );
        for (int i = 0; i < 10; i++) {
          for (int j = 0; j < 10; j++) {
            if (hasObstacle[i][j]) {
              List<Offset> directions = [
                const Offset(-1, 0),
                const Offset(1, 0),
                const Offset(0, -1),
                const Offset(0, 1),
              ];
              directions.shuffle();
              for (var dir in directions) {
                int newRow = i + dir.dx.toInt();
                int newCol = j + dir.dy.toInt();
                if (newRow >= 0 &&
                    newRow < 10 &&
                    newCol >= 0 &&
                    newCol < 10 &&
                    !(newRow == currentRow && newCol == currentCol) &&
                    !hasCollectible[newRow][newCol] &&
                    !(newRow == targetRow && newCol == targetCol)) {
                  newObstacles[newRow][newCol] = true;
                  break;
                }
              }
            }
          }
        }
        hasObstacle = newObstacles;
      });
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (timeLeft > 0) {
          timeLeft--;
        } else {
          isGameOver = true;
          _showGameOverDialog();
          timer.cancel();
        }
      });
    });
  }

  void _showGameOverDialog() {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Game Over',
                    style: GoogleFonts.orbitron(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Score: $score\nLevel: $level\nCycle: $cycle',
                    style: GoogleFonts.orbitron(
                      color: Colors.white70,
                      fontSize: 18,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          if (mounted) {
                            setState(() {
                              score = 0;
                              level = 1;
                              cycle = 0;
                              _initializeLevel();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(
                            0xFF00FFFF,
                          ).withValues(alpha: 0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Restart',
                          style: GoogleFonts.orbitron(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          widget.onGameSelected?.call(0);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          'Back to Games',
                          style: GoogleFonts.orbitron(
                            color: Colors.white70,
                            fontSize: 16,
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
    );
  }

  void _moveInDirection(Direction dir) {
    if (isGameOver || !mounted) return;
    setState(() {
      int newRow = currentRow;
      int newCol = currentCol;

      switch (dir) {
        case Direction.up:
          if (currentRow > 0) newRow--;
          break;
        case Direction.down:
          if (currentRow < 9) newRow++;
          break;
        case Direction.left:
          if (currentCol > 0) newCol--;
          break;
        case Direction.right:
          if (currentCol < 9) newCol++;
          break;
        case Direction.none:
          return;
      }

      if (hasObstacle[newRow][newCol]) return;

      currentRow = newRow;
      currentCol = newCol;

      if (level == 2) {
        movesLeft--;
        if (movesLeft <= 0) {
          isGameOver = true;
          _showGameOverDialog();
          return;
        }
      }

      if (level == 1 || level == 2) {
        if (hasCollectible[currentRow][currentCol]) {
          score++;
          hasCollectible[currentRow][currentCol] = false;
          _spawnCollectibles(level == 1 ? 1 : 3 + cycle); // Scale gems
        }
      } else if (level == 3 &&
          currentRow == targetRow &&
          currentCol == targetCol) {
        score += 10;
        _initializeLevel();
      }

      if (score >=
          (level == 1
              ? 5 + cycle * 2
              : level == 2
              ? 10 + cycle * 3
              : 30 + cycle * 5)) {
        level++;
        if (level > 3) {
          level = 1; // Loop back to Level 1
          cycle++; // Increment cycle
        }
        _initializeLevel();
      }
    });
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _hazardTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF00FFFF),
        scaffoldBackgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Color(0xFF00FFFF)),
        textTheme: TextTheme(
          bodyLarge: GoogleFonts.orbitron(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: Text(
            'Galactic Cat Collector',
            style: GoogleFonts.orbitron(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF00FFFF),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white70),
            onPressed: () => widget.onGameSelected?.call(0),
          ),
        ),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF0A0A1E).withValues(alpha: 0.9),
                Color(0xFF1A1A3A).withValues(alpha: 0.7),
              ],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: _NebulaBackground()),
              SafeArea(
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: animate_do.FadeIn(
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF00FFFF,
                                ).withValues(alpha: 0.3),
                                blurRadius: 12,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Text(
                            level == 1
                                ? 'Level $level (Cycle $cycle): Collect Stars\nScore: $score'
                                : level == 2
                                ? 'Level $level (Cycle $cycle): Collect Gems\nScore: $score\nMoves: $movesLeft'
                                : 'Level $level (Cycle $cycle): Reach Target\nScore: $score\nTime: $timeLeft s',
                            style: GoogleFonts.orbitron(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF00FFFF),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double maxSize =
                              constraints.maxWidth < constraints.maxHeight
                              ? constraints.maxWidth
                              : constraints.maxHeight;
                          return Align(
                            alignment: Alignment.topCenter,
                            child: SizedBox(
                              width: maxSize,
                              height: maxSize,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(
                                        0xFF0A0A1E,
                                      ).withValues(alpha: 0.5),
                                      const Color(
                                        0xFF1A1A3A,
                                      ).withValues(alpha: 0.3),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.4),
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: GridView.builder(
                                  physics: const NeverScrollableScrollPhysics(),
                                  gridDelegate:
                                      const SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 10,
                                        childAspectRatio: 1.0,
                                        crossAxisSpacing: 1,
                                        mainAxisSpacing: 1,
                                      ),
                                  itemCount: 100,
                                  itemBuilder: (context, index) {
                                    int row = index ~/ 10;
                                    int col = index % 10;
                                    bool isPlayer =
                                        (row == currentRow &&
                                        col == currentCol);
                                    bool isCollectible =
                                        hasCollectible[row][col];
                                    bool isObstacle = hasObstacle[row][col];
                                    bool isTarget =
                                        (level == 3 &&
                                        row == targetRow &&
                                        col == targetCol);

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: gridColors[row][col],
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          width: 0.5,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: isPlayer
                                            ? animate_do.Pulse(
                                                duration: const Duration(
                                                  milliseconds: 1000,
                                                ),
                                                child: Transform.scale(
                                                  scale: 1.0,
                                                  child: Image.asset(
                                                    'assets/cat.png',
                                                    fit: BoxFit.contain,
                                                  ),
                                                ),
                                              )
                                            : isCollectible
                                            ? animate_do.Pulse(
                                                duration: const Duration(
                                                  milliseconds: 800,
                                                ),
                                                child: Icon(
                                                  level == 1
                                                      ? Icons.star
                                                      : Icons.diamond,
                                                  size: 15,
                                                  color: level == 1
                                                      ? Colors.yellowAccent
                                                      : Colors.blueAccent,
                                                ),
                                              )
                                            : isObstacle
                                            ? animate_do.Bounce(
                                                duration: const Duration(
                                                  milliseconds: 1000,
                                                ),
                                                child: Icon(
                                                  Icons.block,
                                                  size: 15,
                                                  color: Colors.red.withValues(
                                                    alpha: 0.8,
                                                  ),
                                                ),
                                              )
                                            : isTarget
                                            ? animate_do.Pulse(
                                                duration: const Duration(
                                                  milliseconds: 800,
                                                ),
                                                child: const Icon(
                                                  Icons.flag,
                                                  size: 15,
                                                  color: Colors.greenAccent,
                                                ),
                                              )
                                            : null,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        level == 1
                            ? 'Move to collect stars!'
                            : level == 2
                            ? 'Collect gems, avoid walls!'
                            : 'Reach the target, dodge hazards!',
                        style: GoogleFonts.orbitron(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                bottom: 20,
                right: 20,
                child: GestureDetector(
                  onPanStart: (_) =>
                      setState(() => _joystickDelta = Offset.zero),
                  onPanUpdate: (details) {
                    if (!mounted) return;
                    setState(() {
                      double distance = details.localPosition.distance;
                      if (distance > _joystickRadius) {
                        double scale = _joystickRadius / distance;
                        _joystickDelta = Offset(
                          details.localPosition.dx * scale,
                          details.localPosition.dy * scale,
                        );
                      } else {
                        _joystickDelta = details.localPosition;
                      }
                    });

                    Direction newDirection = Direction.none;
                    double magnitude = _joystickDelta.distance;
                    if (magnitude > _moveThreshold) {
                      if (_joystickDelta.dx.abs() > _joystickDelta.dy.abs()) {
                        newDirection = _joystickDelta.dx > 0
                            ? Direction.right
                            : Direction.left;
                      } else {
                        newDirection = _joystickDelta.dy > 0
                            ? Direction.down
                            : Direction.up;
                      }
                    }

                    if (newDirection != _currentMoveDirection) {
                      _moveTimer?.cancel();
                      _currentMoveDirection = newDirection;
                      if (newDirection != Direction.none) {
                        _moveInDirection(newDirection);
                        _moveTimer = Timer.periodic(
                          const Duration(milliseconds: 300),
                          (timer) {
                            if (!mounted) {
                              timer.cancel();
                              return;
                            }
                            _moveInDirection(_currentMoveDirection);
                          },
                        );
                      }
                    }
                  },
                  onPanEnd: (_) {
                    _moveTimer?.cancel();
                    _currentMoveDirection = Direction.none;
                    if (mounted) {
                      setState(() => _joystickDelta = Offset.zero);
                    }
                  },
                  child: Container(
                    width: _joystickRadius * 2,
                    height: _joystickRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          Colors.black.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: const Color(0xFF00FFFF).withValues(alpha: 0.6),
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FFFF).withValues(alpha: 0.4),
                          blurRadius: 12,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: _joystickRadius + _joystickDelta.dx - 17.5,
                          top: _joystickRadius + _joystickDelta.dy - 17.5,
                          child: Container(
                            width: 35,
                            height: 35,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.4),
                                  Colors.white.withValues(alpha: 0.2),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00FFFF,
                                  ).withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
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
          Colors.purple.withValues(alpha: 0.3),
          Colors.blue.withValues(alpha: 0.2),
          Colors.transparent,
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..blendMode = BlendMode.overlay;

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.4),
      size.width * 0.5,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.7),
      size.width * 0.4,
      paint..color = Colors.purple.withValues(alpha: 0.25),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
