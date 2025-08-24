class Post {
  final String userName;
  final String text;
  final String? mediaPath;
  final String? mediaType;
  final DateTime timestamp;
  final double mediaHeight;

  Post({
    required this.userName,
    required this.text,
    this.mediaPath,
    this.mediaType,
    required this.timestamp,
    this.mediaHeight = 200.0,
  });

  Map<String, dynamic> toJson() => {
    'userName': userName,
    'text': text,
    'mediaPath': mediaPath,
    'mediaType': mediaType,
    'timestamp': timestamp.toIso8601String(),
    'mediaHeight': mediaHeight,
  };

  factory Post.fromJson(Map<String, dynamic> json) => Post(
    userName: json['userName'] as String,
    text: json['text'] as String,
    mediaPath: json['mediaPath'] as String?,
    mediaType: json['mediaType'] as String?,
    timestamp: DateTime.parse(json['timestamp'] as String),
    mediaHeight: (json['mediaHeight'] as num?)?.toDouble() ?? 200.0,
  );
}
