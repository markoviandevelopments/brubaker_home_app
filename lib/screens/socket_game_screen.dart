import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart' as animate_do;
import 'dart:math';
import 'dart:async';
import 'dart:ui';

enum Direction { none, up, down, left, right }

class Ghost {
  int row;
  int col;
  Color color;

  Ghost(this.row, this.col, this.color);
}

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
  Timer? _moveTimer;
  Timer? _ghostTimer;
  Timer? _countdownTimer;
  Timer? _scaleTimer;
  bool isGameOver = false;
  Offset _joystickDelta = Offset.zero;
  final double _joystickRadius = 60.0;
  final double _moveThreshold = 40.0;
  Direction _currentMoveDirection = Direction.none;
  List<Ghost> ghosts = [];
  double _playerScale = 1.0;
  final List<Color> ghostColors = [
    Colors.red,
    Colors.pink,
    Colors.orange,
    Colors.cyan,
  ];

  @override
  void initState() {
    super.initState();
    _playerScale = 1.0;
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
      ghosts.clear();

      if (level == 1) {
        _spawnCollectibles(10 + cycle * 2);
      } else if (level == 2) {
        _spawnObstacles(15 + cycle * 3);
        _spawnCollectibles(12 + cycle * 2);
      } else if (level == 3) {
        _spawnObstacles(20 + cycle * 3);
        _spawnCollectibles(8 + cycle * 2);
        _spawnGhosts(2 + (cycle ~/ 2));
        _startGhostTimer();
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
    int placed = 0;
    while (placed < count) {
      int x = random.nextInt(10);
      int y = random.nextInt(10);
      if (!hasCollectible[x][y] &&
          !hasObstacle[x][y] &&
          !(x == currentRow && y == currentCol)) {
        hasCollectible[x][y] = true;
        placed++;
      }
    }
  }

  void _spawnObstacles(int count) {
    int placed = 0;
    while (placed < count) {
      int x = random.nextInt(10);
      int y = random.nextInt(10);
      if (!hasCollectible[x][y] &&
          !hasObstacle[x][y] &&
          !(x == currentRow && y == currentCol)) {
        hasObstacle[x][y] = true;
        placed++;
      }
    }
  }

  void _spawnGhosts(int count) {
    int placed = 0;
    while (placed < count) {
      int x = random.nextInt(10);
      int y = random.nextInt(10);
      if (!hasObstacle[x][y] &&
          !(x == currentRow && y == currentCol) &&
          !ghosts.any((g) => g.row == x && g.col == y)) {
        ghosts.add(Ghost(x, y, ghostColors[placed % ghostColors.length]));
        placed++;
      }
    }
  }

  void _startGhostTimer() {
    _ghostTimer?.cancel();
    _ghostTimer = Timer.periodic(
      Duration(milliseconds: (500 - cycle * 50).clamp(200, 500)),
      (timer) {
        if (!mounted || isGameOver) {
          timer.cancel();
          return;
        }
        setState(() {
          for (var ghost in ghosts) {
            List<Direction> prefs = [];
            if (currentRow < ghost.row) prefs.add(Direction.up);
            if (currentRow > ghost.row) prefs.add(Direction.down);
            if (currentCol < ghost.col) prefs.add(Direction.left);
            if (currentCol > ghost.col) prefs.add(Direction.right);
            if (prefs.isEmpty) {
              prefs = [
                Direction.up,
                Direction.down,
                Direction.left,
                Direction.right,
              ];
            }
            prefs.shuffle();

            bool moved = false;
            for (var dir in prefs) {
              int nr = ghost.row;
              int nc = ghost.col;
              switch (dir) {
                case Direction.up:
                  if (nr > 0) nr--;
                  break;
                case Direction.down:
                  if (nr < 9) nr++;
                  break;
                case Direction.left:
                  if (nc > 0) nc--;
                  break;
                case Direction.right:
                  if (nc < 9) nc++;
                  break;
                default:
              }
              if (nr != ghost.row || nc != ghost.col) {
                if (!hasObstacle[nr][nc] &&
                    !ghosts.any(
                      (g) => g != ghost && g.row == nr && g.col == nc,
                    )) {
                  ghost.row = nr;
                  ghost.col = nc;
                  moved = true;
                  if (nr == currentRow && nc == currentCol) {
                    isGameOver = true;
                    _showGameOverDialog();
                  }
                  break;
                }
              }
            }
            if (!moved) {
              var allDirs = [
                Direction.up,
                Direction.down,
                Direction.left,
                Direction.right,
              ]..shuffle();
              for (var dir in allDirs) {
                int nr = ghost.row;
                int nc = ghost.col;
                switch (dir) {
                  case Direction.up:
                    if (nr > 0) nr--;
                    break;
                  case Direction.down:
                    if (nr < 9) nr++;
                    break;
                  case Direction.left:
                    if (nc > 0) nc--;
                    break;
                  case Direction.right:
                    if (nc < 9) nc++;
                    break;
                  default:
                }
                if (nr != ghost.row || nc != ghost.col) {
                  if (!hasObstacle[nr][nc] &&
                      !ghosts.any(
                        (g) => g != ghost && g.row == nr && g.col == nc,
                      )) {
                    ghost.row = nr;
                    ghost.col = nc;
                    if (nr == currentRow && nc == currentCol) {
                      isGameOver = true;
                      _showGameOverDialog();
                    }
                    break;
                  }
                }
              }
            }
          }
        });
      },
    );
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

      if (ghosts.any((g) => g.row == currentRow && g.col == currentCol)) {
        isGameOver = true;
        _showGameOverDialog();
        return;
      }

      if (level == 2) {
        movesLeft--;
        if (movesLeft <= 0) {
          isGameOver = true;
          _showGameOverDialog();
          return;
        }
      }

      if (hasCollectible[currentRow][currentCol]) {
        score++;
        hasCollectible[currentRow][currentCol] = false;
      }

      bool allCollected = !hasCollectible.expand((row) => row).any((b) => b);
      if (allCollected) {
        score += level * 5;
        level++;
        if (level > 3) {
          level = 1;
          cycle++;
        }
        _initializeLevel();
      }
    });
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _ghostTimer?.cancel();
    _countdownTimer?.cancel();
    _scaleTimer?.cancel();
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
            'Galactic Cat Pacventure',
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
                                : 'Level $level (Cycle $cycle): Collect Crystals\nScore: $score\nTime: $timeLeft s',
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
                                    Ghost? ghostHere;
                                    try {
                                      ghostHere = ghosts.firstWhere(
                                        (g) => g.row == row && g.col == col,
                                      );
                                    } catch (e) {
                                      ghostHere = null;
                                    }

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
                                        child: ghostHere != null
                                            ? animate_do.ShakeX(
                                                duration: const Duration(
                                                  milliseconds: 1000,
                                                ),
                                                child: Icon(
                                                  Icons.adb,
                                                  size: 15,
                                                  color: ghostHere.color,
                                                ),
                                              )
                                            : isPlayer
                                            ? GestureDetector(
                                                onTap: () {
                                                  if (_scaleTimer?.isActive ??
                                                      false) {
                                                    return;
                                                  }
                                                  setState(
                                                    () => _playerScale = 1.2,
                                                  );
                                                  _scaleTimer = Timer(
                                                    const Duration(
                                                      milliseconds: 300,
                                                    ),
                                                    () {
                                                      if (mounted) {
                                                        setState(
                                                          () => _playerScale =
                                                              1.0,
                                                        );
                                                      }
                                                    },
                                                  );
                                                },
                                                child: animate_do.Pulse(
                                                  duration: const Duration(
                                                    milliseconds: 1000,
                                                  ),
                                                  child: Transform.scale(
                                                    scale: _playerScale,
                                                    child: Image.asset(
                                                      'assets/cat.png',
                                                      fit: BoxFit.contain,
                                                    ),
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
                                                      : level == 2
                                                      ? Icons.diamond
                                                      : Icons.favorite,
                                                  size: 15,
                                                  color: level == 1
                                                      ? Colors.yellowAccent
                                                      : level == 2
                                                      ? Colors.blueAccent
                                                      : Colors.purpleAccent,
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
                            ? 'Collect all stars!'
                            : level == 2
                            ? 'Collect all gems, avoid walls!'
                            : 'Collect all crystals, dodge ghosts!',
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
