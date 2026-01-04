import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart' as animate_do;
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:io';
import 'package:brubaker_homeapp/screens/star_field.dart';
import 'package:provider/provider.dart';
import 'package:brubaker_homeapp/theme.dart';

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
  int lives = 9;
  late List<List<bool>> hasCollectible;
  late List<List<bool>> hasObstacle;
  late List<List<Color>> gridColors;
  Timer? _moveTimer;
  Timer? _ghostTimer;
  Timer? _scaleTimer;
  bool isGameOver = false;
  Offset _joystickDelta = Offset.zero;
  final double _joystickRadius = 60.0;
  final double _moveThreshold = 40.0;
  Direction _currentMoveDirection = Direction.none;
  List<Ghost> ghosts = [];
  double _playerScale = 1.0;
  final Random random = Random();

  @override
  void initState() {
    super.initState();
    _playerScale = 1.0;
    hasCollectible = List.generate(10, (_) => List.generate(10, (_) => false));
    hasObstacle = List.generate(10, (_) => List.generate(10, (_) => false));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Galactic colors only
    gridColors = List.generate(
      10,
      (_) => List.generate(10, (_) => _getGridColor()),
    );
    _initializeGame();
  }

  Color _getGridColor() {
    final baseColor = Theme.of(context).colorScheme.surface;
    return baseColor.withOpacity(0.2 + random.nextDouble() * 0.1);
  }

  Map<String, Color> _getColors(BuildContext context) {
    return {
      'background': Theme.of(context).scaffoldBackgroundColor,
      'surface': Theme.of(context).colorScheme.surface,
      'primary': Theme.of(context).primaryColor,
      'secondary': Theme.of(context).colorScheme.secondary,
      'text': Theme.of(context).textTheme.bodyLarge!.color!,
      'ghost': Colors.red,
      'collectible': Colors.yellowAccent,
      'obstacle': Colors.red,
    };
  }

  Map<String, dynamic> _getIcons() {
    return {'collectible': '⭐', 'ghost': Icons.adb, 'player': 'assets/cat.png'};
  }

  void _initializeGame() {
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
      score = 0;
      lives = 9;
      isGameOver = false;
      ghosts.clear();
      _spawnCollectibles(10 + score ~/ 5);
      _spawnObstacles(10 + score ~/ 5);
      _spawnGhosts(1 + score ~/ 10);
      _startGhostTimer();
    });
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
    final colors = _getColors(context);
    while (placed < count) {
      int x = random.nextInt(10);
      int y = random.nextInt(10);
      if (!hasObstacle[x][y] &&
          !(x == currentRow && y == currentCol) &&
          !ghosts.any((g) => g.row == x && g.col == y)) {
        ghosts.add(Ghost(x, y, colors['ghost']!));
        placed++;
      }
    }
  }

  void _startGhostTimer() {
    _ghostTimer?.cancel();
    _ghostTimer = Timer.periodic(
      Duration(milliseconds: (500 - score * 5).clamp(200, 500)),
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
                    lives--;
                    if (lives <= 0) {
                      isGameOver = true;
                      _showGameOverDialog();
                    } else {
                      _resetPlayerPosition();
                    }
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
                      lives--;
                      if (lives <= 0) {
                        isGameOver = true;
                        _showGameOverDialog();
                      } else {
                        _resetPlayerPosition();
                      }
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

  void _resetPlayerPosition() {
    setState(() {
      currentRow = 0;
      currentCol = 0;
      _playerScale = 1.2;
      _scaleTimer?.cancel();
      _scaleTimer = Timer(const Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() => _playerScale = 1.0);
        }
      });
    });
  }

  void _showGameOverDialog() {
    final colors = _getColors(context);
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
                gradient: LinearGradient(
                  colors: [
                    colors['surface']!.withOpacity(0.3),
                    colors['background']!.withOpacity(0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: colors['text']!.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Game Over',
                    style: GoogleFonts.orbitron(
                      color: colors['text'],
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: colors['primary']!.withOpacity(0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Score: $score\nLives Left: $lives',
                    style: GoogleFonts.orbitron(
                      color: colors['text']!.withOpacity(0.7),
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
                              _initializeGame();
                            });
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors['primary']!.withOpacity(0.8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          side: BorderSide(
                            color: colors['primary']!.withOpacity(0.7),
                          ),
                        ),
                        child: Text(
                          'Restart',
                          style: GoogleFonts.orbitron(
                            color: colors['text'],
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
                          backgroundColor: colors['surface']!.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: BorderSide(
                              color: colors['text']!.withOpacity(0.3),
                            ),
                          ),
                        ),
                        child: Text(
                          'Back to Games',
                          style: GoogleFonts.orbitron(
                            color: colors['text']!.withOpacity(0.7),
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
        lives--;
        if (lives <= 0) {
          isGameOver = true;
          _showGameOverDialog();
        } else {
          _resetPlayerPosition();
        }
        return;
      }

      if (hasCollectible[currentRow][currentCol]) {
        score++;
        hasCollectible[currentRow][currentCol] = false;
        bool allCollected = !hasCollectible.expand((row) => row).any((b) => b);
        if (allCollected) {
          _spawnCollectibles(10 + score ~/ 5);
          _spawnObstacles(10 + score ~/ 5);
          _spawnGhosts(1 + score ~/ 10);
        }
      }
    });
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    _ghostTimer?.cancel();
    _scaleTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = _getColors(context);
    final icons = _getIcons();
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'Galactic Cat Pacventure',
          style: GoogleFonts.orbitron(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: colors['text'],
            shadows: [
              Shadow(
                color: colors['primary']!.withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: colors['text']!.withOpacity(0.7)),
          onPressed: () => widget.onGameSelected?.call(0),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors['background']!.withOpacity(0.9),
              colors['surface']!.withOpacity(0.7),
            ],
          ),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: StarField(opacity: 0.4)),
            Positioned.fill(
              child: _NebulaBackground(
                primaryColor: colors['primary']!,
                secondaryColor: colors['secondary']!,
              ),
            ),
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
                          gradient: LinearGradient(
                            colors: [
                              colors['surface']!.withOpacity(0.4),
                              colors['background']!.withOpacity(0.4),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(
                            color: colors['text']!.withOpacity(0.3),
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: colors['primary']!.withOpacity(0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Score: $score',
                              style: GoogleFonts.orbitron(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colors['text'],
                              ),
                            ),
                            Row(
                              children: List.generate(
                                lives,
                                (index) => Icon(
                                  Icons.favorite,
                                  size: 20,
                                  color: colors['secondary'],
                                ),
                              ),
                            ),
                          ],
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
                                    colors['surface']!.withOpacity(0.5),
                                    colors['background']!.withOpacity(0.3),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(
                                  color: colors['text']!.withOpacity(0.4),
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
                                      (row == currentRow && col == currentCol);
                                  bool isCollectible = hasCollectible[row][col];
                                  bool isObstacle = hasObstacle[row][col];
                                  Ghost? ghostHere = ghosts.firstWhereOrNull(
                                    (g) => g.row == row && g.col == col,
                                  );

                                  return Container(
                                    decoration: BoxDecoration(
                                      color: gridColors[row][col],
                                      border: Border.all(
                                        color: colors['text']!.withOpacity(0.2),
                                        width: 0.5,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: colors['primary']!.withOpacity(
                                            0.1,
                                          ),
                                          blurRadius: 4,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: ghostHere != null
                                          ? animate_do.Flash(
                                              duration: const Duration(
                                                milliseconds: 600,
                                              ),
                                              child: Icon(
                                                icons['ghost'] as IconData,
                                                color: ghostHere.color,
                                                size: 15,
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
                                                        () =>
                                                            _playerScale = 1.0,
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
                                                  child: Text(
                                                    icons['player'] as String,
                                                    style: TextStyle(
                                                      fontSize: 20,
                                                      color: colors['text'],
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            )
                                          : isCollectible
                                          ? animate_do.Pulse(
                                              duration: const Duration(
                                                milliseconds: 800,
                                              ),
                                              child: Text(
                                                icons['collectible'] as String,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  color: colors['collectible'],
                                                ),
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
                                                color: colors['obstacle']!
                                                    .withOpacity(0.8),
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
                      'Collect stars ⭐, dodge enemies!',
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        color: colors['text']!.withOpacity(0.7),
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
                onPanStart: (_) => setState(() => _joystickDelta = Offset.zero),
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
                        colors['background']!.withOpacity(0.3),
                        colors['surface']!.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: colors['primary']!.withOpacity(0.6),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: colors['primary']!.withOpacity(0.4),
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
                                colors['text']!.withOpacity(0.4),
                                colors['text']!.withOpacity(0.2),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: colors['primary']!.withOpacity(0.5),
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
    );
  }
}

class _NebulaBackground extends StatelessWidget {
  final Color primaryColor;
  final Color secondaryColor;

  const _NebulaBackground({
    required this.primaryColor,
    required this.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _NebulaPainter(
        primaryColor: primaryColor,
        secondaryColor: secondaryColor,
      ),
      child: Container(),
    );
  }
}

class _NebulaPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;

  _NebulaPainter({required this.primaryColor, required this.secondaryColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          primaryColor.withOpacity(0.3),
          secondaryColor.withOpacity(0.2),
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
      paint..color = primaryColor.withOpacity(0.25),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

extension IterableExtension<T> on Iterable<T> {
  T? firstWhereOrNull(bool Function(T) test) {
    try {
      return firstWhere(test);
    } catch (e) {
      return null;
    }
  }
}
