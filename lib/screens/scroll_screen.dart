import 'dart:io';
import 'dart:convert';
import 'dart:ui';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../screens/star_field.dart';
import '../models/post.dart';

class ScrollScreen extends StatefulWidget {
  const ScrollScreen({super.key});

  @override
  ScrollScreenState createState() => ScrollScreenState();
}

class ScrollScreenState extends State<ScrollScreen> {
  List<Post> _posts = [];
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>(); // Safe context handling

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

  void _deletePost(int index) async {
    setState(() {
      _posts.removeAt(index);
    });
    await _savePosts();
    _scaffoldMessengerKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          'Post deleted',
          style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 14),
        ),
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey, // Assign the key to Scaffold
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
            Positioned.fill(child: StarField(opacity: 0.3)),
            ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                return PostWidget(
                  post: _posts[index],
                  onDelete: () => _deletePost(index),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.white.withValues(alpha: 0.2),
        elevation: 6,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
          ),
          child: const Icon(Icons.add, color: Colors.white70),
        ),
        onPressed: () => _showPostDialog(context),
      ),
    );
  }

  void _showPostDialog(BuildContext context) {
    String userName = '';
    String text = '';
    File? mediaFile;
    String? mediaType;
    double mediaHeight = 200.0; // Default height for preview and post
    VideoPlayerController? videoController;
    ChewieController? chewieController;

    void _updateMediaPreview() {
      if (mediaFile != null && mediaType == 'video') {
        videoController = VideoPlayerController.file(mediaFile!)
          ..initialize().then((_) {
            chewieController = ChewieController(
              videoPlayerController: videoController!,
              autoPlay: true,
              looping: false,
            );
            if (mounted) setState(() {});
          });
      } else if (mediaFile != null && mediaType == 'image') {
        if (mounted) setState(() {});
      }
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.transparent,
          content: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Your Name',
                          labelStyle: GoogleFonts.orbitron(
                            color: Colors.white70,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        style: GoogleFonts.orbitron(color: Colors.white70),
                        onChanged: (value) => userName = value,
                      ),
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Status Update',
                          labelStyle: GoogleFonts.orbitron(
                            color: Colors.white70,
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                        style: GoogleFonts.orbitron(color: Colors.white70),
                        onChanged: (value) => text = value,
                      ),
                      const SizedBox(height: 16),
                      if (mediaFile != null)
                        Column(
                          children: [
                            mediaType == 'image'
                                ? Image.file(
                                    mediaFile!,
                                    height: mediaHeight,
                                    width: double.infinity,
                                    fit: BoxFit.contain,
                                  )
                                : chewieController != null &&
                                      chewieController!
                                          .videoPlayerController
                                          .value
                                          .isInitialized
                                ? SizedBox(
                                    height: mediaHeight,
                                    width: double.infinity,
                                    child: Chewie(
                                      controller: chewieController!,
                                    ),
                                  )
                                : const CircularProgressIndicator(
                                    color: Colors.white70,
                                  ),
                            Slider(
                              value: mediaHeight,
                              min: 100.0,
                              max: 400.0,
                              divisions: 6,
                              label: '${mediaHeight.round()}px',
                              activeColor: const Color(
                                0xFF00FFD1,
                              ).withValues(alpha: 0.7),
                              inactiveColor: Colors.white.withValues(
                                alpha: 0.3,
                              ),
                              onChanged: (value) {
                                setState(() {
                                  mediaHeight = value;
                                });
                              },
                            ),
                          ],
                        ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              elevation: 6,
                            ),
                            onPressed: () async {
                              final picked = await ImagePicker().pickImage(
                                source: ImageSource.gallery,
                              );
                              if (picked != null) {
                                mediaFile = File(picked.path);
                                mediaType = 'image';
                                _updateMediaPreview();
                              }
                            },
                            child: Text(
                              'Image',
                              style: GoogleFonts.orbitron(
                                color: Colors.white70,
                              ),
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(
                                alpha: 0.2,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              elevation: 6,
                            ),
                            onPressed: () async {
                              final picked = await ImagePicker().pickVideo(
                                source: ImageSource.gallery,
                              );
                              if (picked != null) {
                                mediaFile = File(picked.path);
                                mediaType = 'video';
                                _updateMediaPreview();
                              }
                            },
                            child: Text(
                              'Video',
                              style: GoogleFonts.orbitron(
                                color: Colors.white70,
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
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: GoogleFonts.orbitron(color: Colors.white70),
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
                    mediaHeight: mediaHeight, // Store the selected height
                  );
                  setState(() {
                    _posts.add(newPost);
                  });
                  await _savePosts();
                  Navigator.pop(context);
                  if (videoController != null) {
                    videoController!.dispose();
                  }
                  if (chewieController != null) {
                    chewieController!.dispose();
                  }
                } else {
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    SnackBar(
                      content: Text(
                        'Name and status required',
                        style: GoogleFonts.orbitron(color: Colors.white70),
                      ),
                      backgroundColor: Colors.black.withValues(alpha: 0.8),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Text(
                'Post',
                style: GoogleFonts.orbitron(color: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PostWidget extends StatelessWidget {
  final Post post;
  final VoidCallback onDelete;

  const PostWidget({super.key, required this.post, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post.userName,
                  style: GoogleFonts.orbitron(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  post.text,
                  style: GoogleFonts.orbitron(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                if (post.mediaPath != null && post.mediaType != null) ...[
                  const SizedBox(height: 12),
                  post.mediaType == 'image'
                      ? Image.file(
                          File(post.mediaPath!),
                          height: post.mediaHeight,
                          width: double.infinity,
                          fit: BoxFit.contain,
                        )
                      : Chewie(
                          controller: ChewieController(
                            videoPlayerController: VideoPlayerController.file(
                              File(post.mediaPath!),
                            )..initialize(),
                            autoPlay: false,
                            looping: false,
                            aspectRatio: 16 / 9,
                          ),
                        ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      post.timestamp.toString(),
                      style: GoogleFonts.orbitron(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white54,
                        size: 18,
                      ),
                      onPressed: onDelete,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
