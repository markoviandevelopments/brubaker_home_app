import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';

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
        _showSnackBar(
          'Failed to fetch mode: ${response.statusCode}, ${response.body}',
        );
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
        _showSnackBar(
          'Update failed: ${response.statusCode}, ${response.body}',
        );
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
          style: GoogleFonts.montserrat(color: Colors.white),
        ),
        backgroundColor: Colors.black.withOpacity(0.7),
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
        title: Text(
          'LED Controls',
          style: GoogleFonts.rye(
            color: Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1693368765432-lDivijzEg9o?auto=format&fit=crop&w=1920&q=80',
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.redAccent),
                )
              : ListView(
                  padding: const EdgeInsets.all(16.0),
                  children: [
                    Text(
                      'Current Mode: ${titleCase(currentMode)}',
                      style: GoogleFonts.montserrat(
                        color: Colors.white,
                        fontSize: 18,
                        shadows: [
                          Shadow(
                            blurRadius: 8.0,
                            color: Colors.redAccent.withOpacity(0.5),
                            offset: const Offset(0, 0),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Predefined Modes',
                      style: GoogleFonts.rye(
                        color: Colors.redAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...modes.map(
                      (mode) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: GestureDetector(
                          onTap: isUpdating ? null : () => updateMode(mode),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.5),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: mode == currentMode
                                      ? Colors.redAccent.withOpacity(0.8)
                                      : Colors.blueAccent.withOpacity(0.3),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ListTile(
                              title: Text(
                                titleCase(mode),
                                style: GoogleFonts.montserrat(
                                  color: mode == currentMode
                                      ? Colors.redAccent
                                      : Colors.white,
                                ),
                              ),
                              trailing: Icon(
                                Icons.lightbulb,
                                color: mode == currentMode
                                    ? Colors.redAccent
                                    : Colors.white,
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
