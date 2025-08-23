import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart' as animateDo;
import 'dart:math';
import 'dart:async';

enum Direction { none, up, down, left, right }

class SocketGameScreen extends StatefulWidget {
  final Function(int)? onGameSelected;

  const SocketGameScreen({super.key, this.onGameSelected});

  @override
  _SocketGameScreenState createState() => _SocketGameScreenState();
}

class _SocketGameScreenState extends State<SocketGameScreen>
    with SingleTickerProviderStateMixin {
  int currentRow = 0;
  int currentCol = 0;
  int score = 0;
  int level = 1;
  int movesLeft = 20; // For Level 2
  int timeLeft = 30; // For Level 3 (in seconds)
  final Random random = Random();
  late List<List<bool>> hasCollectible;
  late List<List<bool>>
  hasObstacle; // For walls (Level 2) and hazards (Level 3)
  late List<List<Color>> gridColors;
  int? targetRow, targetCol; // For Level 3 target
  Timer? _moveTimer;
  Timer? _hazardTimer; // For moving hazards in Level 3
  Timer? _countdownTimer; // For Level 3 timer
  bool isGameOver = false;
  Offset _joystickDelta = Offset.zero;
  final double _joystickRadius = 60.0;
  final double _moveThreshold = 30.0;
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
      movesLeft = level == 2 ? 20 : -1; // Moves only for Level 2
      timeLeft = level == 3 ? 30 : -1; // Timer only for Level 3
      isGameOver = false;

      if (level == 1) {
        _spawnCollectibles(3); // Spawn 3 stars
      } else if (level == 2) {
        _spawnCollectibles(2); // Spawn 2 gems
        _spawnObstacles(5); // Spawn 5 walls
      } else if (level == 3) {
        _spawnTarget(); // Spawn target tile
        _spawnObstacles(3); // Spawn 3 moving hazards
        _startHazardTimer();
        _startCountdownTimer();
      }
    });
  }

  Color _getGridColor() {
    if (level == 1) {
      return const Color(
        0xFF0A0A1E,
      ).withOpacity(0.2 + random.nextDouble() * 0.1);
    } else if (level == 2) {
      return const Color(
        0xFF1A1A3A,
      ).withOpacity(0.3 + random.nextDouble() * 0.1);
    } else {
      return const Color(
        0xFF2A0A4A,
      ).withOpacity(0.4 + random.nextDouble() * 0.1);
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
    for (int i = 0; i < count; i++) {
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
    _hazardTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
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
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(
              0.3,
            ), // Increased opacity for clarity
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
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
                'Score: $score\nLevel: $level',
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
                          _initializeLevel();
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00FFFF).withOpacity(0.8),
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
                      widget.onGameSelected?.call(0); // Return to GamesScreen
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: Colors.white.withOpacity(0.3)),
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

      // Check for obstacles
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
          _spawnCollectibles(level == 1 ? 1 : 2);
        }
      } else if (level == 3 &&
          currentRow == targetRow &&
          currentCol == targetCol) {
        score += 10;
        _initializeLevel(); // Restart Level 3
      }

      // Level up thresholds: 5, 15, 30
      if (score >=
          (level == 1
              ? 5
              : level == 2
              ? 15
              : 30)) {
        level++;
        if (level > 3) {
          isGameOver = true;
          _showGameOverDialog();
        } else {
          _initializeLevel();
        }
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
            onPressed: () =>
                widget.onGameSelected?.call(0), // Return to GamesScreen
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A0A1E), Color(0xFF1A1A3A)],
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
                      child: animateDo.FadeIn(
                        duration: const Duration(milliseconds: 600),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 24,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(
                              0.4,
                            ), // Increased opacity
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF00FFFF).withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Text(
                            level == 1
                                ? 'Level $level: Collect Stars\nScore: $score'
                                : level == 2
                                ? 'Level $level: Collect Gems\nScore: $score\nMoves: $movesLeft'
                                : 'Level $level: Reach Target\nScore: $score\nTime: $timeLeft s',
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
                                  color: Colors.black.withOpacity(
                                    0.5,
                                  ), // Increased opacity
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                  ),
                                  borderRadius: BorderRadius.circular(12),
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
                                          color: Colors.white.withOpacity(0.2),
                                          width: 0.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: isPlayer
                                            ? animateDo.Pulse(
                                                duration: const Duration(
                                                  milliseconds: 1000,
                                                ),
                                                child: Transform.scale(
                                                  scale:
                                                      1.0, // Reduced scale for clarity
                                                  child: Image.asset(
                                                    'assets/cat.png',
                                                    fit: BoxFit.contain,
                                                    color: const Color(
                                                      0xFF00FFFF,
                                                    ).withOpacity(0.9),
                                                    colorBlendMode:
                                                        BlendMode.modulate,
                                                  ),
                                                ),
                                              )
                                            : isCollectible
                                            ? animateDo.Pulse(
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
                                            ? animateDo.Bounce(
                                                duration: const Duration(
                                                  milliseconds: 1000,
                                                ),
                                                child: Icon(
                                                  Icons.block,
                                                  size: 15,
                                                  color: Colors.red.withOpacity(
                                                    0.8,
                                                  ),
                                                ),
                                              )
                                            : isTarget
                                            ? animateDo.Pulse(
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
                          const Duration(milliseconds: 200),
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
                      color: Colors.black.withOpacity(0.3), // Increased opacity
                      border: Border.all(
                        color: const Color(0xFF00FFFF).withOpacity(0.5),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00FFFF).withOpacity(0.3),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Positioned(
                          left: _joystickRadius + _joystickDelta.dx - 15,
                          top: _joystickRadius + _joystickDelta.dy - 15,
                          child: Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(
                                0.3,
                              ), // Increased opacity
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00FFFF,
                                  ).withOpacity(0.4),
                                  blurRadius: 8,
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
          Colors.purple.withOpacity(0.3), // Increased opacity for clarity
          Colors.blue.withOpacity(0.2),
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
      paint..color = Colors.purple.withOpacity(0.25), // Increased opacity
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
