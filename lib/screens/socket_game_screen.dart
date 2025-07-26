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
  late List<List<Color>> gridColors; // 2D list for grid colors

  @override
  void initState() {
    super.initState();
    // Initialize 10x10 grid with green color
    gridColors = List.generate(
      10,
      (_) => List.generate(10, (_) => Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Update cat's position in the grid
    gridColors[currentRow][currentCol] = Colors.grey[800]!;

    return Scaffold(
      appBar: AppBar(title: const Text('Socket Game')),
      body: Column(
        children: [
          // Display score above the grid
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Score: $score',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Center(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double maxSize = constraints.maxWidth < constraints.maxHeight
                      ? constraints.maxWidth
                      : constraints.maxHeight;
                  return Container(
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
                        // Use color from 2D list
                        Color color = gridColors[row][col];
                        return Container(color: color);
                      },
                    ),
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Reset current cat position to green
                      gridColors[currentRow][currentCol] = Colors.green;
                      // Move cat up
                      if (currentRow > 0) currentRow--;
                      // Randomly change a cell to yellow
                      int number = random.nextInt(10);
                      if (number == 0) {
                        int x = random.nextInt(10);
                        int y = random.nextInt(10);
                        gridColors[x][y] =
                            Colors.yellow; // Set random cell to yellow
                      }
                      // Check to see if point was earned
                      if (gridColors[currentRow][currentCol] == Colors.yellow) {
                        score++;
                      }
                      // Set new cat position to grey
                      gridColors[currentRow][currentCol] = Colors.grey[800]!;
                    });
                  },
                  child: const Text('Up'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Reset current cat position to green
                      gridColors[currentRow][currentCol] = Colors.green;
                      // Move cat down
                      if (currentRow < 9) currentRow++;
                      // Check to see if point was earned
                      if (gridColors[currentRow][currentCol] == Colors.yellow) {
                        score++;
                      }
                      // Set new cat position to grey
                      gridColors[currentRow][currentCol] = Colors.grey[800]!;
                    });
                  },
                  child: const Text('Down'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Reset current cat position to green
                      gridColors[currentRow][currentCol] = Colors.green;
                      // Move cat left
                      if (currentCol > 0) currentCol--;
                      // Check to see if point was earned
                      if (gridColors[currentRow][currentCol] == Colors.yellow) {
                        score++;
                      }
                      // Set new cat position to grey
                      gridColors[currentRow][currentCol] = Colors.grey[800]!;
                    });
                  },
                  child: const Text('Left'),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      // Reset current cat position to green
                      gridColors[currentRow][currentCol] = Colors.green;
                      // Move cat right
                      if (currentCol < 9) currentCol++;
                      // Set new cat position to grey
                      // Check to see if point was earned
                      if (gridColors[currentRow][currentCol] == Colors.yellow) {
                        score++;
                      }
                      gridColors[currentRow][currentCol] = Colors.grey[800]!;
                    });
                  },
                  child: const Text('Right'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
