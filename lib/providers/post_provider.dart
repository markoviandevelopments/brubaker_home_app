import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/post.dart';

class PostProvider with ChangeNotifier {
  List<Post> _posts = [];

  PostProvider() {
    _init();
  }

  Future<void> _init() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await auth.signInAnonymously();
    }
    _listenToPosts();
  }

  void _listenToPosts() {
    FirebaseFirestore.instance
        .collection('posts')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .listen((snapshot) {
          _posts = snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Post.fromJson(data);
          }).toList();
          notifyListeners();
        });
  }

  Future<void> addPost(
    String userName,
    String text,
    File? mediaFile,
    String? mediaType,
  ) async {
    String? mediaUrl;
    if (mediaFile != null) {
      final extension = mediaType == 'image' ? '.jpg' : '.mp4';
      final ref = FirebaseStorage.instance.ref(
        'media/${const Uuid().v4()}$extension',
      );
      await ref.putFile(mediaFile);
      mediaUrl = await ref.getDownloadURL();
    }

    final data = {
      'userName': userName,
      'text': text,
      'mediaUrl': mediaUrl,
      'mediaType': mediaType,
      'timestamp': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance.collection('posts').add(data);
  }

  List<Post> get posts => _posts;
}
