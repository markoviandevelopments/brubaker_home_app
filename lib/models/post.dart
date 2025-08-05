import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String userName;
  final String text;
  final String? mediaUrl;
  final String? mediaType; // 'image' or 'video'
  final DateTime timestamp;

  Post({
    required this.id,
    required this.userName,
    required this.text,
    this.mediaUrl,
    this.mediaType,
    required this.timestamp,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'],
      userName: json['userName'],
      text: json['text'],
      mediaUrl: json['mediaUrl'],
      mediaType: json['mediaType'],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }
}
