// socket_game_screen.dart
import 'package:flutter/material.dart';
import 'dart:math';

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

  // Swipe detection variables
  Offset? _dragStart;
  Offset? _dragCurrent;
  final double minDragDistance = 50.0; // Threshold for valid swipe

  @override
  void initState() {
    super.initState();
    // Initialize 10x10 grid for collectibles
    hasCollectible = List.generate(10, (_) => List.generate(10, (_) => false));
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
          child: Column(
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
                      return GestureDetector(
                        onPanStart: (details) {
                          _dragStart = details.localPosition;
                          _dragCurrent = details.localPosition;
                        },
                        onPanUpdate: (details) {
                          _dragCurrent = details.localPosition;
                        },
                        onPanEnd: (details) {
                          if (_dragStart == null || _dragCurrent == null)
                            return;
                          final delta = _dragCurrent! - _dragStart!;
                          if (delta.dx.abs() > delta.dy.abs()) {
                            if (delta.dx.abs() > minDragDistance) {
                              if (delta.dx > 0)
                                moveRight();
                              else
                                moveLeft();
                            }
                          } else {
                            if (delta.dy.abs() > minDragDistance) {
                              if (delta.dy > 0)
                                moveDown();
                              else
                                moveUp();
                            }
                          }
                          _dragStart = null;
                          _dragCurrent = null;
                        },
                        child: SizedBox(
                          width: maxSize,
                          height: maxSize,
                          child: GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate:
                                const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 10,
                                  childAspectRatio: 1.0,
                                ),
                            itemCount: 100,
                            itemBuilder: (context, index) {
                              int row = index ~/ 10;
                              int col = index % 10;
                              bool isPlayer =
                                  (row == currentRow && col == currentCol);
                              bool isCollectible = hasCollectible[row][col];

                              return Container(
                                color: Colors
                                    .green, // Green background, no borders
                                child: Center(
                                  child: isPlayer
                                      ? Image.asset(
                                          'assets/cat.png',
                                          fit: BoxFit.contain,
                                        ) // Uploaded cat image; adjust size if needed
                                      : isCollectible
                                      ? const Icon(
                                          Icons.circle,
                                          size: 10,
                                          color: Color(0xFF8B4513),
                                        ) // Kibble as small brown circle; replace with Image.asset for custom
                                      : null,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
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
