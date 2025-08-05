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
                          _dragStart =
                              details.localPosition; // Uses localPosition
                        },
                        onPanEnd: (details) {
                          if (_dragStart == null) return;
                          final dx = details.velocity.pixelsPerSecond.dx;
                          final dy = details.velocity.pixelsPerSecond.dy;
                          if (dx.abs() > dy.abs()) {
                            if (dx > 0)
                              moveRight();
                            else
                              moveLeft();
                          } else {
                            if (dy > 0)
                              moveDown();
                            else
                              moveUp();
                          }
                          _dragStart = null;
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
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.white, Colors.brown[100]!],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  border: Border.all(
                                    color: const Color(0xFF8B4513),
                                    width: 0.5,
                                  ), // Saddle brown border
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 2,
                                      offset: const Offset(1, 1),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: isPlayer
                                      ? const Icon(
                                          Icons.pets,
                                          size: 24,
                                          color: Colors.black,
                                        ) // Cat icon; replace with Image.asset for custom
                                      : isCollectible
                                      ? const Icon(
                                          Icons.star,
                                          size: 24,
                                          color: Colors.yellow,
                                        ) // Star icon; replace with Image.asset
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
