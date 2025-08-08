import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui'; // For BackdropFilter

class LedControlsScreen extends StatefulWidget {
  const LedControlsScreen({super.key});

  @override
  _LedControlsScreenState createState() => _LedControlsScreenState();
}

class _LedControlsScreenState extends State<LedControlsScreen> {
  final String serverUrl = 'http://108.254.1.184:5000';
  final List<String> modes = [
    'off',
    'rainbow-flow',
    'constant-red',
    'proletariat-crackle',
    'soma-haze',
    'loonie-freefall',
    'bokanovsky-burst',
    'total-perspective-vortex',
    'golgafrincham-drift',
    'bistromathics-surge',
    'groks-dissolution',
    'newspeak-shrink',
    'nolite-te-bastardes',
    'infinite-improbability-drive',
    'big-brother-glare',
    'replicant-retirement',
    'water-brother-bond',
    'hypnopaedia-hum',
    'vogon-poetry-pulse',
    'thought-police-flash',
    'electric-sheep-dream',
  ];
  String currentMode = 'off';
  bool isLoading = true;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    fetchCurrentMode();
  }

  Future<void> fetchCurrentMode() async {
    setState(() => isLoading = true);
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/mode'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 && modes.contains(response.body.trim())) {
        setState(() => currentMode = response.body.trim());
      } else {
        _showSnackBar('Failed to fetch mode: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Connection error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateMode(String newMode) async {
    setState(() => isUpdating = true);
    try {
      final response = await http
          .post(
            Uri.parse('$serverUrl/update'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mode': newMode}),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        setState(() => currentMode = newMode);
        _showSnackBar('Mode updated to $newMode');
      } else {
        _showSnackBar('Update failed: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Connection error: $e');
    } finally {
      setState(() => isUpdating = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'Courier', color: Colors.white70),
        ),
        backgroundColor: Colors.black.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String titleCase(String text) {
    return text
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Galactic LED Matrix',
          style: TextStyle(
            fontFamily: 'Courier',
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Color(0xFF00FFFF), // Neon cyan
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0A1E),
              Color(0xFF1A1A3A),
            ], // Starry space gradient
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00FFFF)),
                )
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(
                          sigmaX: 5,
                          sigmaY: 5,
                        ), // Glass effect
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(
                              0.1,
                            ), // Glassy panel
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: Text(
                            'Current Mode: ${titleCase(currentMode)}',
                            style: const TextStyle(
                              fontFamily: 'Courier',
                              color: Colors.white70,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ClipRect(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                            ),
                          ),
                          child: const Text(
                            'Select Mode',
                            style: TextStyle(
                              fontFamily: 'Courier',
                              color: Color(0xFF00FFFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...modes.map(
                      (mode) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: GestureDetector(
                          onTap: isUpdating ? null : () => updateMode(mode),
                          child: ClipRect(
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: mode == currentMode
                                        ? const Color(
                                            0xFF00FFFF,
                                          ).withOpacity(0.8)
                                        : Colors.white.withOpacity(0.2),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: mode == currentMode
                                          ? const Color(
                                              0xFF00FFFF,
                                            ).withOpacity(0.5)
                                          : Colors.black.withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  title: Text(
                                    titleCase(mode),
                                    style: TextStyle(
                                      fontFamily: 'Courier',
                                      color: mode == currentMode
                                          ? const Color(0xFF00FFFF)
                                          : Colors.white70,
                                    ),
                                  ),
                                  trailing: Icon(
                                    Icons.star, // Star icon for space vibe
                                    color: mode == currentMode
                                        ? const Color(0xFF00FFFF)
                                        : Colors.white70,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
