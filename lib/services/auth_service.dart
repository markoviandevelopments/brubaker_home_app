import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class User {
  final String name;
  final String email;

  User({required this.name, required this.email});
}

class AuthService extends ChangeNotifier {
  User? _currentUser;
  User? get currentUser => _currentUser;

  Future<bool> signUp(String name, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    if (await _emailExists(email)) return false; // Email taken

    final hashedPassword = _hashPassword(password);
    await prefs.setString('user_name', name);
    await prefs.setString('user_email', email);
    await prefs.setString('user_password', hashedPassword);
    _currentUser = User(name: name, email: email);
    notifyListeners();
    return true;
  }

  Future<bool> login(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    final storedEmail = prefs.getString('user_email');
    final storedPassword = prefs.getString('user_password');

    if (storedEmail == email && storedPassword == _hashPassword(password)) {
      final name = prefs.getString('user_name') ?? '';
      _currentUser = User(name: name, email: email);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    _currentUser = null;
    notifyListeners();
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey('user_email');
  }

  Future<bool> _emailExists(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_email') == email;
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }
}
