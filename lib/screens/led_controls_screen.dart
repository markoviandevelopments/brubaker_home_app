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
          style: GoogleFonts.montserrat(
            color: Theme.of(context).colorScheme.onSurface, // Light theme text
          ),
        ),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface, // Light background
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
      appBar: AppBar(
        title: Text(
          'LED Controls',
          style: GoogleFonts.montserrat(
            color: Theme.of(context).colorScheme.secondary, // Red accent
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Theme.of(
          context,
        ).colorScheme.surface, // Light background
        elevation: 0,
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.secondary, // Red accent
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Current Mode: ${titleCase(currentMode)}',
                  style: GoogleFonts.montserrat(
                    color: Theme.of(context).colorScheme.onSurface, // Dark text
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Predefined Modes',
                  style: GoogleFonts.montserrat(
                    color: Theme.of(
                      context,
                    ).colorScheme.secondary, // Red accent
                    fontWeight: FontWeight.w600,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 10),
                ...modes.map(
                  (mode) => Card(
                    child: ListTile(
                      title: Text(
                        titleCase(mode),
                        style: GoogleFonts.montserrat(
                          color: mode == currentMode
                              ? Theme.of(context)
                                    .colorScheme
                                    .secondary // Red for selected
                              : Theme.of(
                                  context,
                                ).colorScheme.primary, // Brown for unselected
                        ),
                      ),
                      trailing: Icon(
                        Icons.lightbulb,
                        color: mode == currentMode
                            ? Theme.of(context)
                                  .colorScheme
                                  .secondary // Red for selected
                            : Theme.of(
                                context,
                              ).colorScheme.primary, // Brown for unselected
                      ),
                      onTap: isUpdating ? null : () => updateMode(mode),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
