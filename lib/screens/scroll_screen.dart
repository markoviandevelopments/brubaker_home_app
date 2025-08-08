import 'dart:io';
import 'dart:convert';
import 'dart:ui'; // For BackdropFilter
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../models/post.dart';

class ScrollScreen extends StatefulWidget {
  const ScrollScreen({super.key});

  @override
  _ScrollScreenState createState() => _ScrollScreenState();
}

class _ScrollScreenState extends State<ScrollScreen> {
  List<Post> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = prefs.getStringList('posts') ?? [];
    setState(() {
      _posts = postsJson
          .map((jsonStr) => Post.fromJson(jsonDecode(jsonStr)))
          .toList();
    });
  }

  Future<void> _savePosts() async {
    final prefs = await SharedPreferences.getInstance();
    final postsJson = _posts.map((post) => jsonEncode(post.toJson())).toList();
    await prefs.setStringList('posts', postsJson);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A1E), Color(0xFF1A1A3A)], // Starry gradient
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16.0),
          itemCount: _posts.length,
          itemBuilder: (context, index) {
            return PostWidget(post: _posts[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF00FFFF), // Neon cyan
        child: const Icon(Icons.add, color: Colors.black),
        onPressed: () => _showPostDialog(context),
      ),
    );
  }

  void _showPostDialog(BuildContext context) {
    String userName = '';
    String text = '';
    File? mediaFile;
    String? mediaType;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        content: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Glass effect
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Your Name',
                      labelStyle: TextStyle(
                        color: Color(0xFF00FFFF),
                        fontFamily: 'Courier',
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FFFF)),
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Courier',
                    ),
                    onChanged: (value) => userName = value,
                  ),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Status Update',
                      labelStyle: TextStyle(
                        color: Color(0xFF00FFFF),
                        fontFamily: 'Courier',
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF00FFFF)),
                      ),
                    ),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontFamily: 'Courier',
                    ),
                    onChanged: (value) => text = value,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FFFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final picked = await ImagePicker().pickImage(
                            source: ImageSource.gallery,
                          );
                          if (picked != null) {
                            mediaFile = File(picked.path);
                            mediaType = 'image';
                          }
                        },
                        child: const Text(
                          'Image',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Courier',
                          ),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00FFFF),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: () async {
                          final picked = await ImagePicker().pickVideo(
                            source: ImageSource.gallery,
                          );
                          if (picked != null) {
                            mediaFile = File(picked.path);
                            mediaType = 'video';
                          }
                        },
                        child: const Text(
                          'Video',
                          style: TextStyle(
                            color: Colors.black,
                            fontFamily: 'Courier',
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: Color(0xFFFF00FF), // Magenta
                fontFamily: 'Courier',
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              if (userName.isNotEmpty && text.isNotEmpty) {
                final newPost = Post(
                  userName: userName,
                  text: text,
                  mediaPath: mediaFile?.path,
                  mediaType: mediaType,
                  timestamp: DateTime.now(),
                );
                setState(() {
                  _posts.add(newPost);
                });
                await _savePosts();
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Name and status required',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        color: Colors.white70,
                      ),
                    ),
                    backgroundColor: Colors.black87,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text(
              'Post',
              style: TextStyle(color: Color(0xFFFF00FF), fontFamily: 'Courier'),
            ),
          ),
        ],
      ),
    );
  }
}

class PostWidget extends StatelessWidget {
  final Post post;

  const PostWidget({super.key, required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5), // Glass effect
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.userName,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    color: Color(0xFF00FFFF),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.text,
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                if (post.mediaPath != null && post.mediaType != null) ...[
                  const SizedBox(height: 12),
                  post.mediaType == 'image'
                      ? Image.file(
                          File(post.mediaPath!),
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Chewie(
                          controller: ChewieController(
                            videoPlayerController: VideoPlayerController.file(
                              File(post.mediaPath!),
                            )..initialize(),
                            autoPlay: false,
                            looping: false,
                          ),
                        ),
                ],
                const SizedBox(height: 8),
                Text(
                  post.timestamp.toString(),
                  style: const TextStyle(
                    fontFamily: 'Courier',
                    color: Colors.white54,
                    fontSize: 12,
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
