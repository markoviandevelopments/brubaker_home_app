import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:brubaker_homeapp/screens/star_field.dart';
import 'dart:convert';
import 'dart:ui';
import 'dart:io'; // Added for SocketException handling

class LedControlsScreen extends StatefulWidget {
  final Function(int)? onGameSelected;

  const LedControlsScreen({super.key, this.onGameSelected});

  @override
  _LedControlsScreenState createState() => _LedControlsScreenState();
}

class _LedControlsScreenState extends State<LedControlsScreen>
    with SingleTickerProviderStateMixin {
  static const String localServerUrl = 'http://192.168.1.126:5000';
  static const String publicServerUrl = 'http://108.254.1.184:5000';
  String serverUrl = localServerUrl; // Default to local
  final List<Map<String, String>> modes = [
    {'name': 'off', 'image': 'assets/modes/off.png'},
    {'name': 'rainbow-flow', 'image': 'assets/modes/rainbow-flow.png'},
    {'name': 'constant-red', 'image': 'assets/modes/constant-red.png'},
    {
      'name': 'proletariat-crackle',
      'image': 'assets/modes/proletariat-crackle.png',
    },
    {'name': 'soma-haze', 'image': 'assets/modes/soma-haze.png'},
    {'name': 'loonie-freefall', 'image': 'assets/modes/loonie-freefall.png'},
    {'name': 'bokanovsky-burst', 'image': 'assets/modes/bokanovsky-burst.png'},
    {
      'name': 'total-perspective-vortex',
      'image': 'assets/modes/total-perspective-vortex.png',
    },
    {
      'name': 'golgafrincham-drift',
      'image': 'assets/modes/golgafrincham-drift.png',
    },
    {
      'name': 'bistromathics-surge',
      'image': 'assets/modes/bistromathics-surge.png',
    },
    {
      'name': 'groks-dissolution',
      'image': 'assets/modes/groks-dissolution.png',
    },
    {'name': 'newspeak-shrink', 'image': 'assets/modes/newspeak-shrink.png'},
    {
      'name': 'nolite-te-bastardes',
      'image': 'assets/modes/nolite-te-bastardes.png',
    },
    {
      'name': 'infinite-improbability-drive',
      'image': 'assets/modes/infinite-improbability-drive.png',
    },
    {
      'name': 'big-brother-glare',
      'image': 'assets/modes/big-brother-glare.png',
    },
    {
      'name': 'replicant-retirement',
      'image': 'assets/modes/replicant-retirement.png',
    },
    {
      'name': 'water-brother-bond',
      'image': 'assets/modes/water-brother-bond.png',
    },
    {'name': 'hypnopaedia-hum', 'image': 'assets/modes/hypnopaedia-hum.png'},
    {
      'name': 'vogon-poetry-pulse',
      'image': 'assets/modes/vogon-poetry-pulse.png',
    },
    {
      'name': 'thought-police-flash',
      'image': 'assets/modes/thought-police-flash.png',
    },
    {
      'name': 'electric-sheep-dream',
      'image': 'assets/modes/electric-sheep-dream.png',
    },
    {'name': 'qrng', 'image': 'assets/modes/qrng.png'},
  ];
  String currentMode = 'off';
  bool isLoading = true;
  bool isUpdating = false;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    checkServerAvailability();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  Future<void> checkServerAvailability() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      // Try local server first
      final response = await http
          .get(Uri.parse('$localServerUrl/mode'))
          .timeout(const Duration(seconds: 2)); // Short timeout for quick check
      if (response.statusCode == 200) {
        setState(() => serverUrl = localServerUrl); // Local server is available
      } else {
        setState(() => serverUrl = publicServerUrl); // Fallback to public
      }
    } catch (e) {
      setState(
        () => serverUrl = publicServerUrl,
      ); // Fallback to public on error
    } finally {
      await fetchCurrentMode(); // Fetch mode after determining server
    }
  }

  Future<void> fetchCurrentMode() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final response = await http
          .get(Uri.parse('$serverUrl/mode'))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200 &&
          modes.any((mode) => mode['name'] == response.body.trim())) {
        if (mounted) {
          setState(() => currentMode = response.body.trim());
        }
      } else {
        _showSnackBar('Failed to fetch mode: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Connection error: $e');
      // Optionally retry with public server if local fails
      if (serverUrl == localServerUrl) {
        setState(() => serverUrl = publicServerUrl);
        await fetchCurrentMode(); // Retry with public server
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> updateMode(String newMode) async {
    if (!mounted) return;
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
        if (mounted) {
          setState(() => currentMode = newMode);
          _showSnackBar('Mode updated to $newMode');
        }
      } else {
        _showSnackBar('Update failed: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Connection error: $e');
      // Optionally retry with public server if local fails
      if (serverUrl == localServerUrl) {
        setState(() => serverUrl = publicServerUrl);
        await updateMode(newMode); // Retry with public server
      }
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.orbitron(color: Colors.white70, fontSize: 14),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF0A0A1E), Color(0xFF1A1A3A)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: StarField(opacity: 0.2)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Galactic LED Matrix',
                        style: GoogleFonts.orbitron(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Colors.white70,
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16.0),
                          children: [
                            ClipRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.3),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      AnimatedBuilder(
                                        animation: _glowAnimation,
                                        builder: (context, child) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white
                                                      .withOpacity(
                                                        0.4 *
                                                            _glowAnimation
                                                                .value,
                                                      ),
                                                  blurRadius:
                                                      12 * _glowAnimation.value,
                                                  spreadRadius:
                                                      4 * _glowAnimation.value,
                                                ),
                                              ],
                                            ),
                                            child: Image.asset(
                                              modes.firstWhere(
                                                (mode) =>
                                                    mode['name'] == currentMode,
                                              )['image']!,
                                              width: 100,
                                              height: 100,
                                              fit: BoxFit.cover,
                                              errorBuilder:
                                                  (
                                                    context,
                                                    error,
                                                    stackTrace,
                                                  ) => const Icon(
                                                    Icons.image_not_supported,
                                                    color: Colors.white70,
                                                    size: 100,
                                                  ),
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Current Mode: ${titleCase(currentMode)}',
                                          style: GoogleFonts.orbitron(
                                            color: Colors.white70,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            ClipRect(
                              child: BackdropFilter(
                                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                                child: AnimatedBuilder(
                                  animation: _glowAnimation,
                                  builder: (context, child) {
                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                        ),
                                      ),
                                      child: Text(
                                        'Select Mode',
                                        style: GoogleFonts.orbitron(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 20,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    crossAxisSpacing: 12,
                                    mainAxisSpacing: 12,
                                    childAspectRatio: 0.75,
                                  ),
                              itemCount: modes.length,
                              itemBuilder: (context, index) {
                                final mode = modes[index];
                                return GestureDetector(
                                  onTap: isUpdating
                                      ? null
                                      : () => updateMode(mode['name']!),
                                  child: ClipRect(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 5,
                                        sigmaY: 5,
                                      ),
                                      child: AnimatedBuilder(
                                        animation: _glowAnimation,
                                        builder: (context, child) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.2,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color:
                                                    mode['name'] == currentMode
                                                    ? Colors.white.withOpacity(
                                                        0.8 *
                                                            _glowAnimation
                                                                .value,
                                                      )
                                                    : Colors.white.withOpacity(
                                                        0.3,
                                                      ),
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color:
                                                      mode['name'] ==
                                                          currentMode
                                                      ? Colors.white
                                                            .withOpacity(
                                                              0.4 *
                                                                  _glowAnimation
                                                                      .value,
                                                            )
                                                      : Colors.black
                                                            .withOpacity(0.3),
                                                  blurRadius:
                                                      10 * _glowAnimation.value,
                                                  spreadRadius:
                                                      2 * _glowAnimation.value,
                                                ),
                                              ],
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Expanded(
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                          8.0,
                                                        ),
                                                    child: Image.asset(
                                                      mode['image']!,
                                                      fit: BoxFit.contain,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => const Icon(
                                                            Icons
                                                                .image_not_supported,
                                                            color:
                                                                Colors.white70,
                                                            size: 120,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  titleCase(mode['name']!),
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.orbitron(
                                                    color:
                                                        mode['name'] ==
                                                            currentMode
                                                        ? Colors.white
                                                        : Colors.white70,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
