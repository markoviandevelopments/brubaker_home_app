// lib/screens/scroll_screen.dart

import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path; // For extracting filename from path

import 'star_field.dart'; // Only the default galactic background

class ScrollScreen extends StatefulWidget {
  const ScrollScreen({super.key});

  @override
  State<ScrollScreen> createState() => _ScrollScreenState();
}

class _ScrollScreenState extends State<ScrollScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      key: _scaffoldMessengerKey,
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [theme.scaffoldBackgroundColor, theme.colorScheme.surface],
          ),
        ),
        child: Stack(
          children: [
            // Default starfield – subtle and cosmic
            const Positioned.fill(child: StarField(opacity: 0.4)),

            // Nebula glow using app theme colors
            Positioned.fill(
              child: _NebulaBackground(
                primaryColor: theme.primaryColor,
                secondaryColor: theme.colorScheme.secondary,
              ),
            ),

            // Image gallery list
            SafeArea(
              child: FutureBuilder<List<String>>(
                future: _loadImagesFromServer(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final images = snapshot.data ?? [];

                  if (images.isEmpty) {
                    return Center(
                      child: Text(
                        'No images yet...\nTap + to share one!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.orbitron(
                          color: theme.textTheme.bodyLarge!.color!.withOpacity(
                            0.7,
                          ),
                          fontSize: 18,
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: images.length,
                    itemBuilder: (context, index) {
                      final imagePath = images[index];
                      final imageUrl = 'http://192.168.1.198:6042$imagePath';
                      final filename = path.basename(
                        imagePath,
                      ); // e.g., 'photo.jpg' for display

                      return Dismissible(
                        key: Key(imagePath), // Unique key for each image
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: Colors.red[700],
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await _showDeleteConfirmation(
                            context,
                            filename,
                          );
                        },
                        onDismissed: (direction) {
                          _deleteImage(imagePath);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.surface.withOpacity(
                                    0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: theme.textTheme.bodyLarge!.color!
                                        .withOpacity(0.3),
                                    width: 2,
                                  ),
                                ),
                                child: Image.network(
                                  imageUrl,
                                  fit: BoxFit.contain,
                                  loadingBuilder:
                                      (context, child, loadingProgress) {
                                        if (loadingProgress == null)
                                          return child;
                                        return Container(
                                          height: 300,
                                          color: Colors.white.withOpacity(0.1),
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 200,
                                      color: Colors.red.withOpacity(0.2),
                                      child: Center(
                                        child: Icon(
                                          Icons.error,
                                          color: Colors.red[300],
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
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // FAB for image upload – themed to galactic primary
      floatingActionButton: FloatingActionButton(
        backgroundColor: theme.primaryColor.withOpacity(0.8),
        elevation: 12,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [theme.primaryColor, theme.primaryColor.withOpacity(0.6)],
            ),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.add_a_photo, color: Colors.white, size: 28),
        ),
        onPressed: () => _uploadImage(context),
      ),
    );
  }

  Future<bool> _showDeleteConfirmation(
    BuildContext context,
    String filename,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surface.withOpacity(0.9),
            title: Text(
              'Delete Image?',
              style: GoogleFonts.orbitron(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Are you sure you want to remove "$filename" from the frame? This action cannot be undone.',
              style: GoogleFonts.orbitron(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.orbitron(color: Colors.grey[600]),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(
                  'Delete',
                  style: GoogleFonts.orbitron(color: Colors.red[400]),
                ),
              ),
            ],
          ),
        ) ??
        false; // Default to false if dialog is dismissed
  }

  Future<void> _deleteImage(String imagePath) async {
    try {
      final response = await http.delete(
        Uri.parse(
          'http://192.168.1.198:6042/images$imagePath',
        ), // Assumes DELETE /images/{path}
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Image deleted successfully!',
              style: GoogleFonts.orbitron(color: Colors.white),
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {}); // Refresh the list
      } else {
        throw Exception('Delete failed: ${response.statusCode}');
      }
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Delete failed: $e',
            style: GoogleFonts.orbitron(color: Colors.white),
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Revert the dismiss if delete fails (add back to list)
      setState(() {});
    }
  }

  Future<List<String>> _loadImagesFromServer() async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.1.198:6042/images'),
      );
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        return list.cast<String>();
      }
    } catch (e) {
      print('Error loading images: $e');
    }
    return [];
  }

  Future<void> _uploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    final filename = pickedFile.name;

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.1.198:6042/upload'),
      );
      request.files.add(
        http.MultipartFile.fromBytes('image', bytes, filename: filename),
      );

      final response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Image uploaded successfully!',
              style: GoogleFonts.orbitron(color: Colors.white),
            ),
            backgroundColor: Colors.green[700],
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() {}); // Refresh the list
      } else {
        throw Exception('Upload failed');
      }
    } catch (e) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text(
            'Upload failed: $e',
            style: GoogleFonts.orbitron(color: Colors.white),
          ),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}

// Reusable nebula glow – tied to theme
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
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.3),
          secondaryColor.withOpacity(0.2),
          Colors.transparent,
        ],
        center: const Alignment(0.3, 0.4),
        radius: 0.6,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..blendMode = BlendMode.overlay;

    canvas.drawCircle(
      Offset(size.width * 0.3, size.height * 0.4),
      size.width * 0.6,
      paint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.7, size.height * 0.7),
      size.width * 0.5,
      paint..color = primaryColor.withOpacity(0.25),
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
