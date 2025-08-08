import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import 'dart:ui'; // For BackdropFilter
import 'package:animate_do/animate_do.dart';

enum Direction { none, up, down, left, right }

class SocketGameScreen extends StatefulWidget {
  const SocketGameScreen({super.key});

  @override
  _SocketGameScreenState createState() => _SocketGameScreenState();
}

class _SocketGameScreenState extends State<SocketGameScreen> {
  int currentRow = 0;
  int currentCol = 0;
  int score = 0;
  final random = Random();
  late List<List<bool>> hasCollectible;
  late List<List<Color>> gridColors; // For subtle starry variations

  // Joystick variables
  Offset _joystickDelta = Offset.zero;
  final double _joystickRadius = 60.0;
  final double _moveThreshold = 30.0;
  Direction _currentMoveDirection = Direction.none;
  Timer? _moveTimer;

  @override
  void initState() {
    super.initState();
    hasCollectible = List.generate(10, (_) => List.generate(10, (_) => false));
    gridColors = List.generate(
      10,
      (_) => List.generate(
        10,
        (_) => const Color(
          0xFF0A0A1E,
        ).withOpacity(0.2 + random.nextDouble() * 0.1),
      ),
    );
    spawnCollectibleChance(); // Initial spawn
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    super.dispose();
  }

  void spawnCollectibleChance() {
    if (random.nextInt(10) == 0) {
      int x = random.nextInt(10);
      int y = random.nextInt(10);
      if (!hasCollectible[x][y] && !(x == currentRow && y == currentCol)) {
        setState(() {
          hasCollectible[x][y] = true;
        });
      }
    }
  }

  void moveUp() {
    setState(() {
      if (currentRow > 0) currentRow--;
      spawnCollectibleChance();
      if (hasCollectible[currentRow][currentCol]) {
        score++;
        hasCollectible[currentRow][currentCol] = false;
      }
    });
  }

  void moveDown() {
    setState(() {
      if (currentRow < 9) currentRow++;
      spawnCollectibleChance();
      if (hasCollectible[currentRow][currentCol]) {
        score++;
        hasCollectible[currentRow][currentCol] = false;
      }
    });
  }

  void moveLeft() {
    setState(() {
      if (currentCol > 0) currentCol--;
      spawnCollectibleChance();
      if (hasCollectible[currentRow][currentCol]) {
        score++;
        hasCollectible[currentRow][currentCol] = false;
      }
    });
  }

  void moveRight() {
    setState(() {
      if (currentCol < 9) currentCol++;
      spawnCollectibleChance();
      if (hasCollectible[currentRow][currentCol]) {
        score++;
        hasCollectible[currentRow][currentCol] = false;
      }
    });
  }

  void _moveInDirection(Direction dir) {
    switch (dir) {
      case Direction.up:
        moveUp();
        break;
      case Direction.down:
        moveDown();
        break;
      case Direction.left:
        moveLeft();
        break;
      case Direction.right:
        moveRight();
        break;
      case Direction.none:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF00FFFF),
        scaffoldBackgroundColor: const Color(0xFF0A0A1E),
        iconTheme: const IconThemeData(color: Color(0xFF00FFFF)),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(
            color: Colors.white,
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          title: const Text(
            'Galactic Collector',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Courier',
              color: Color(0xFF00FFFF),
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF0A0A1E), Color(0xFF1A1A3A)],
            ),
          ),
          child: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: ClipRect(
                        child: BackdropFilter(
                          filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 24,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.transparent,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(
                                    0xFF00FFFF,
                                  ).withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'Score: $score',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Courier',
                                color: Color(0xFF00FFFF),
                              ),
                              textAlign: TextAlign.center,
                            ),
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
                              child: ClipRect(
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 3,
                                    sigmaY: 3,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.transparent,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.3),
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: GridView.builder(
                                      physics:
                                          const NeverScrollableScrollPhysics(),
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

                                        return FadeIn(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          child: ClipRect(
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: 2,
                                                sigmaY: 2,
                                              ),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: gridColors[row][col],
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.1),
                                                    width: 0.5,
                                                  ),
                                                ),
                                                child: Center(
                                                  child: isPlayer
                                                      ? Pulse(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    1000,
                                                              ),
                                                          child: Transform.scale(
                                                            scale: 1.5,
                                                            child: Image.asset(
                                                              'assets/cat.png',
                                                              fit: BoxFit
                                                                  .contain,
                                                              color:
                                                                  const Color(
                                                                    0xFF00FFFF,
                                                                  ).withOpacity(
                                                                    0.9,
                                                                  ),
                                                              colorBlendMode:
                                                                  BlendMode
                                                                      .modulate,
                                                            ),
                                                          ),
                                                        )
                                                      : isCollectible
                                                      ? Pulse(
                                                          duration:
                                                              const Duration(
                                                                milliseconds:
                                                                    800,
                                                              ),
                                                          child: const Icon(
                                                            Icons.star,
                                                            size: 15,
                                                            color: Color(
                                                              0xFFFF00FF,
                                                            ),
                                                          ),
                                                        )
                                                      : null,
                                                ),
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 20,
                  right: 20,
                  child: GestureDetector(
                    onPanStart: (_) =>
                        setState(() => _joystickDelta = Offset.zero),
                    onPanUpdate: (details) {
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
                              _moveInDirection(_currentMoveDirection);
                            },
                          );
                        }
                      }
                    },
                    onPanEnd: (_) {
                      _moveTimer?.cancel();
                      _currentMoveDirection = Direction.none;
                      setState(() => _joystickDelta = Offset.zero);
                    },
                    child: ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                        child: Container(
                          width: _joystickRadius * 2,
                          height: _joystickRadius * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
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
                                    color: Colors.white.withOpacity(0.2),
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
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
