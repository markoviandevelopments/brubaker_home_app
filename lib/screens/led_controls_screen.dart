import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class LedControlsScreen extends StatefulWidget {
  const LedControlsScreen({super.key});

  @override
  _LedControlsScreenState createState() => _LedControlsScreenState();
}

class _LedControlsScreenState extends State<LedControlsScreen> {
  final String serverUrl = 'http://192.168.1.126:5000';
  final List<String> modes = [
    'off',
    'rainbow-flow',
    'constant-red',
    'proletariat-crackle',
    'bourgeois-brilliance',
    'austere-enlightenment',
    'zaphod-galactic-groove',
    'max-aquarian-flow',
    'lunar-rebellion-pulse',
    'proletariat-pulse',
    'bourgeois-blaze',
  ];
  String currentMode = 'off';
  bool isLoading = true;
  bool isUpdating = false;
  Color selectedColor = Colors.white;
  String selectedPattern = 'solid';
  double speed = 1.0; // Default speed (0.5-5.0)

  final List<String> patterns = ['solid', 'pulse', 'fade', 'chase'];

  @override
  void initState() {
    super.initState();
    fetchCurrentMode();
  }

  Future<void> fetchCurrentMode() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse('$serverUrl/mode'));
      if (response.statusCode == 200 && modes.contains(response.body.trim())) {
        setState(() => currentMode = response.body.trim());
      } else {
        _showSnackBar('Failed to fetch mode');
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
      final response = await http.post(
        Uri.parse('$serverUrl/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'mode': newMode}),
      );
      if (response.statusCode == 200) {
        setState(() => currentMode = newMode);
        _showSnackBar('Mode updated!');
      } else {
        _showSnackBar('Update failed');
      }
    } catch (e) {
      _showSnackBar('Connection error: $e');
    } finally {
      setState(() => isUpdating = false);
    }
  }

  Future<void> updateCustom() async {
    setState(() => isUpdating = true);
    final hexColor =
        '#${selectedColor.value.toRadixString(16).padLeft(8, '0').substring(2)}';
    try {
      final response = await http.post(
        Uri.parse('$serverUrl/update'), // Or custom endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'mode': 'custom',
          'color': hexColor,
          'pattern': selectedPattern,
          'speed': speed,
        }),
      );
      if (response.statusCode == 200) {
        _showSnackBar('Custom LED applied!');
      } else {
        _showSnackBar('Custom update failed');
      }
    } catch (e) {
      _showSnackBar('Connection error: $e');
    } finally {
      setState(() => isUpdating = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LED Controls')),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                Text(
                  'Current Mode: $currentMode',
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Predefined Modes:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ...modes.map(
                  (mode) => ListTile(
                    title: Text(mode.replaceAll('-', ' ').toUpperCase()),
                    trailing: Icon(
                      Icons.star,
                      color: Theme.of(context).colorScheme.secondary,
                    ), // Red accent
                    selected: currentMode == mode,
                    onTap: isUpdating ? null : () => updateMode(mode),
                  ),
                ),
                const Divider(),
                const Text(
                  'Custom Color LED:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                ColorPicker(
                  pickerColor: selectedColor,
                  onColorChanged: (color) =>
                      setState(() => selectedColor = color),
                  enableAlpha: false,
                  labelTypes: const [],
                ),
                DropdownButton<String>(
                  value: selectedPattern,
                  onChanged: (v) => setState(() => selectedPattern = v!),
                  items: patterns
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(p.toUpperCase()),
                        ),
                      )
                      .toList(),
                ),
                const Text('Speed:'),
                Slider(
                  value: speed,
                  min: 0.5,
                  max: 5.0,
                  divisions: 9,
                  label: speed.toStringAsFixed(1),
                  activeColor: Theme.of(
                    context,
                  ).colorScheme.secondary, // Red accent
                  onChanged: (v) => setState(() => speed = v),
                ),
                ElevatedButton(
                  onPressed: isUpdating ? null : updateCustom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ), // Brown accent
                  child: const Text('Apply Custom'),
                ),
              ],
            ),
    );
  }
}
