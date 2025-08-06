// socket_game_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';

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
  late List<List<bool>> hasCollectible; // 2D list for collectible positions

  // Joystick variables
  Offset _joystickDelta = Offset.zero;
  final double _joystickRadius = 60.0;
  final double _moveThreshold = 30.0; // Half radius for activation
  Direction _currentMoveDirection = Direction.none;
  Timer? _moveTimer;

  @override
  void initState() {
    super.initState();
    // Initialize 10x10 grid for collectibles
    hasCollectible = List.generate(10, (_) => List.generate(10, (_) => false));
  }

  @override
  void dispose() {
    _moveTimer?.cancel();
    super.dispose();
  }

  void spawnCollectibleChance() {
    // Randomly spawn a collectible
    if (random.nextInt(10) == 0) {
      int x = random.nextInt(10);
      int y = random.nextInt(10);
      // Avoid spawning on player
      if (!hasCollectible[x][y] && !(x == currentRow && y == currentCol)) {
        hasCollectible[x][y] = true;
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
      data: ThemeData(
        primaryColor: const Color(0xFF8B4513), // Saddle brown accent
        scaffoldBackgroundColor: Colors.white, // Clean white background
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Socket Game'),
          backgroundColor: const Color(0xFF8B4513), // Saddle brown app bar
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Display score above the grid
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      'Score: $score',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double maxSize =
                              constraints.maxWidth < constraints.maxHeight
                              ? constraints.maxWidth
                              : constraints.maxHeight;
                          return SizedBox(
                            width: maxSize,
                            height: maxSize,
                            child: GridView.builder(
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 10,
                                    childAspectRatio: 1.0,
                                    crossAxisSpacing: 0, // No gaps
                                    mainAxisSpacing: 0, // No gaps
                                  ),
                              itemCount: 100,
                              itemBuilder: (context, index) {
                                int row = index ~/ 10;
                                int col = index % 10;
                                bool isPlayer =
                                    (row == currentRow && col == currentCol);
                                bool isCollectible = hasCollectible[row][col];

                                return Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.green[600]!,
                                        Colors.green[400]!,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ), // Subtle grass texture via gradient
                                  ),
                                  child: Center(
                                    child: isPlayer
                                        ? Image.asset(
                                            'assets/cat.png',
                                            fit: BoxFit.contain,
                                          ) // Ensure asset added; adjust size if needed
                                        : isCollectible
                                        ? const Icon(
                                            Icons.circle,
                                            size: 10,
                                            color: Color(0xFF8B4513),
                                          ) // Kibble
                                        : null,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
              // Joystick at bottom-right
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

                    // Handle continuous movement
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
                        // Immediate move
                        _moveInDirection(newDirection);
                        // Repeat while held
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
                  child: Container(
                    width: _joystickRadius * 2,
                    height: _joystickRadius * 2,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.brown[200]!.withOpacity(
                        0.5,
                      ), // Cowboy accent, semi-transparent
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(2, 2),
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
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF8B4513), // Saddle brown knob
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
