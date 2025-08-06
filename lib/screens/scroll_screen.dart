import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../models/post.dart';

class ScrollScreen extends StatefulWidget {
  const ScrollScreen({super.key});

  @override
  _ScrollScreenState createState() => _ScrollScreenState();
}

class _ScrollScreenState extends State<ScrollScreen> {
  final List<Post> _posts = []; // Local in-memory posts

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView.builder(
        padding: const EdgeInsets.all(16.0),
        itemCount: _posts.length,
        itemBuilder: (context, index) {
          return PostWidget(post: _posts[index]);
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF8B4513), // Brown cowboy accent
        child: const Icon(Icons.add, color: Colors.white),
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
        backgroundColor: Colors.white, // Clean white
        title: const Text('New Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Your Name',
                labelStyle: TextStyle(color: Color(0xFF8B4513)),
              ),
              onChanged: (value) => userName = value,
            ),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Status Update',
                labelStyle: TextStyle(color: Color(0xFF8B4513)),
              ),
              onChanged: (value) => text = value,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
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
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B4513),
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
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF8B4513)),
            ),
          ),
          TextButton(
            onPressed: () {
              if (userName.isNotEmpty && text.isNotEmpty) {
                setState(() {
                  _posts.add(
                    Post(
                      userName: userName,
                      text: text,
                      mediaPath: mediaFile?.path,
                      mediaType: mediaType,
                      timestamp: DateTime.now(),
                    ),
                  );
                });
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Post',
              style: TextStyle(color: Color(0xFF8B4513)),
            ),
          ),
        ],
      ),
    );
  }
}

class PostWidget extends StatefulWidget {
  final Post post;
  const PostWidget({super.key, required this.post});

  @override
  State<PostWidget> createState() => _PostWidgetState();
}

class _PostWidgetState extends State<PostWidget> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    if (widget.post.mediaType == 'video' && widget.post.mediaPath != null) {
      _videoController = VideoPlayerController.file(
        File(widget.post.mediaPath!),
      );
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        aspectRatio: 16 / 9,
      );
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget mediaWidget = const SizedBox.shrink();
    if (widget.post.mediaPath != null) {
      if (widget.post.mediaType == 'image') {
        mediaWidget = Image.file(
          File(widget.post.mediaPath!),
          fit: BoxFit.cover,
        );
      } else if (widget.post.mediaType == 'video') {
        mediaWidget = SizedBox(
          height: 200,
          child: Chewie(controller: _chewieController!),
        );
      }
    }

    return Card(
      color: Colors.white, // Clean white
      elevation: 2, // Modern shadow
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.person,
                color: Color(0xFF8B4513),
              ), // Cowboy accent
              title: Text(
                widget.post.userName,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(widget.post.text),
            ),
            mediaWidget,
            const SizedBox(height: 8),
            Text(
              widget.post.timestamp.toLocal().toString().split(
                '.',
              )[0], // Clean timestamp
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
