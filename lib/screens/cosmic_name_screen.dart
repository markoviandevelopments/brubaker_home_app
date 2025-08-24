import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:brubaker_homeapp/screens/star_field.dart';
import 'dart:convert';
import 'dart:ui';
import 'dart:async';
import 'dart:io';

class CosmicNameScreen extends StatefulWidget {
  final Function(int) onGameSelected;

  const CosmicNameScreen({super.key, required this.onGameSelected});

  @override
  CosmicNameScreenState createState() => CosmicNameScreenState();
}

class CosmicNameScreenState extends State<CosmicNameScreen>
    with SingleTickerProviderStateMixin {
  String _epochTime = '';
  String _randomNumber = '';
  String _numVisits = '';
  String _tribalName = '';
  String _errorMessage = '';
  bool _isLoading = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  Socket? _socket;
  StreamSubscription<List<int>>? _subscription;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..forward();
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeIn));
    _fetchData();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _disconnect();
    super.dispose();
  }

  Future<void> _fetchData() async {
    await _disconnect();
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
      _epochTime = '';
      _randomNumber = '';
      _numVisits = '';
      _tribalName = '';
    });
    _fadeController.reset();
    try {
      _socket = await Socket.connect(
        '108.254.1.184',
        5090,
      ).timeout(const Duration(seconds: 5));
      _subscription = _socket!.listen(
        (List<int> data) {
          if (!mounted) return;
          try {
            final response = utf8.decode(data, allowMalformed: true);
            final jsonData = jsonDecode(response);
            setState(() {
              _epochTime = jsonData['epoch_time']?.toString() ?? 'N/A';
              _randomNumber = jsonData['random_number']?.toString() ?? 'N/A';
              _numVisits = jsonData['num visits']?.toString() ?? 'N/A';
              _tribalName = jsonData['tribal name'] ?? 'N/A';
              _isLoading = false;
            });
            _fadeController.forward();
            _disconnect();
          } catch (e) {
            if (mounted) {
              setState(() {
                _errorMessage = 'Error parsing data: $e';
                _isLoading = false;
              });
            }
            _disconnect();
          }
        },
        onError: (error) {
          if (mounted) {
            setState(() {
              _errorMessage = 'Socket error: $error';
              _isLoading = false;
            });
          }
          _disconnect();
        },
        onDone: () {
          if (mounted) {
            setState(() {
              _errorMessage = _tribalName.isEmpty
                  ? 'Connection closed unexpectedly'
                  : '';
              _isLoading = false;
            });
          }
          _disconnect();
        },
        cancelOnError: true,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Connection error: $e';
          _isLoading = false;
        });
      }
      _disconnect();
    }
  }

  Future<void> _disconnect() async {
    if (_subscription != null) {
      await _subscription!.cancel();
      _subscription = null;
    }
    if (_socket != null) {
      await _socket!.close();
      _socket = null;
    }
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white70,
                        ),
                        onPressed: () =>
                            widget.onGameSelected(0), // Return to GamesScreen
                      ),
                      Text(
                        'Galactic Name Weaver',
                        style: GoogleFonts.orbitron(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 30), // Placeholder for symmetry
                    ],
                  ),
                ),
                Expanded(
                  child: Center(
                    child: _isLoading
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: Colors.white70,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Weaving your cosmic name...',
                                style: GoogleFonts.orbitron(
                                  color: Colors.white70,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          )
                        : FadeTransition(
                            opacity: _fadeAnimation,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (_errorMessage.isNotEmpty) ...[
                                  ClipRect(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 5,
                                        sigmaY: 5,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          _errorMessage,
                                          style: GoogleFonts.orbitron(
                                            color: const Color(0xFF8B0000),
                                            fontSize: 14,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ],
                                if (_tribalName.isNotEmpty) ...[
                                  ClipRect(
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 5,
                                        sigmaY: 5,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                          ),
                                        ),
                                        child: Column(
                                          children: [
                                            Text(
                                              'Your Cosmic Identity',
                                              style: GoogleFonts.orbitron(
                                                color: Colors.white70,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 18,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Silly Name: $_tribalName',
                                              style: GoogleFonts.orbitron(
                                                color: Colors.white,
                                                fontSize: 16,
                                              ),
                                            ),
                                            Text(
                                              'Epoch Time: $_epochTime',
                                              style: GoogleFonts.orbitron(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              'Random Number: $_randomNumber',
                                              style: GoogleFonts.orbitron(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              'Num Visits: $_numVisits',
                                              style: GoogleFonts.orbitron(
                                                color: Colors.white70,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                ] else
                                  Text(
                                    'Tap to discover your galactic name!',
                                    style: GoogleFonts.orbitron(
                                      color: Colors.white70,
                                      fontSize: 16,
                                    ),
                                  ),
                                const SizedBox(height: 20),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.4 * _fadeAnimation.value,
                                        ),
                                        blurRadius: 10 * _fadeAnimation.value,
                                        spreadRadius: 2 * _fadeAnimation.value,
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: _isLoading ? null : _fetchData,
                                    child: Text(
                                      _errorMessage.isNotEmpty
                                          ? 'Retry'
                                          : 'Fetch Data',
                                      style: GoogleFonts.orbitron(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.white.withValues(
                                          alpha: 0.4 * _fadeAnimation.value,
                                        ),
                                        blurRadius: 10 * _fadeAnimation.value,
                                        spreadRadius: 2 * _fadeAnimation.value,
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white.withValues(
                                        alpha: 0.2,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        side: BorderSide(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 24,
                                        vertical: 12,
                                      ),
                                    ),
                                    onPressed: () => widget.onGameSelected(
                                      0,
                                    ), // Return to GamesScreen
                                    child: Text(
                                      'Back to Games',
                                      style: GoogleFonts.orbitron(
                                        color: Colors.white70,
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
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
