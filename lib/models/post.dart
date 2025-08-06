import 'package:flutter/foundation.dart';

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
}
