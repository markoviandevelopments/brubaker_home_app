import 'package:flutter/foundation.dart';
import 'dart:convert'; // For jsonEncode/jsonDecode

class Post {
  final String userName;
  final String text;
  final String? mediaPath; // Local file path instead of URL
  final String? mediaType;
  final DateTime timestamp;

  Post({
    required this.userName,
    required this.text,
    this.mediaPath,
    this.mediaType,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'text': text,
    'mediaPath': mediaPath,
    'mediaType': mediaType,
    'timestamp': timestamp.toIso8601String(),
  };

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    userName: json['userName'],
    text: json['text'],
    mediaPath: json['mediaPath'],
    mediaType: json['mediaType'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}
