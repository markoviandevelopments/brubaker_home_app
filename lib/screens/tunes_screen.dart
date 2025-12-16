import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';
import 'package:brubaker_homeapp/screens/star_field.dart';
import 'package:brubaker_homeapp/screens/spooky_field.dart';
import 'package:provider/provider.dart';
import 'package:brubaker_homeapp/theme.dart';
import 'dart:convert';
import 'dart:ui';
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

class GalacticTunesScreen extends StatefulWidget {
  const GalacticTunesScreen({super.key});

  @override
  GalacticTunesScreenState createState() => GalacticTunesScreenState();
}

class GalacticTunesScreenState extends State<GalacticTunesScreen>
    with SingleTickerProviderStateMixin {
  static const String clientId = 'b1c6e93d9747441b9c9de632cd72c1e5';
  static const String clientSecret = 'de9fccd48c454d92b9a8b627eac4a67e';
  static const String redirectUri = 'com.brubaker.homeapp://callback';
  static const String spotifyAuthUrl = 'https://accounts.spotify.com/authorize';
  static const String spotifyTokenUrl =
      'https://accounts.spotify.com/api/token';
  static const String spotifyApiUrl = 'https://api.spotify.com/v1';
  static const String localServerUrl = 'http://192.168.1.198:5000';
  static const String publicServerUrl = 'http://108.254.1.184:5000';
  String serverUrl = localServerUrl;

  final List<Map<String, String>> tracks = [
    {
      'name': 'Butterfly',
      'artist': 'Crazy Town',
      'uri': 'spotify:track:4BggEwLhGfrbrl7JBhC8EC',
      'image': 'assets/tracks/bat-toad.png',
      'ledMode': 'loonie-freefall',
    },
    {
      'name': 'Birdhouse in Your Soul',
      'artist': 'They Might Be Giants',
      'uri': 'spotify:track:6pmuu4qSz2WrtGkBjUfyuz',
      'image': 'assets/tracks/candy-corn-toad.png',
      'ledMode': 'golgafrincham-drift',
    },
    {
      'name': 'Axel F',
      'artist': 'Crazy Frog',
      'uri': 'spotify:track:0Bo5fjMtTfCD8vHGebivqc',
      'image': 'assets/tracks/jack-o-toad.png',
      'ledMode': 'newspeak-shrink',
    },
    {
      'name': 'The HampsterDance Song',
      'artist': 'Hampton The Hampster',
      'uri': 'spotify:track:0ouSkB2t2fGeW60MPcvmXl',
      'image': 'assets/tracks/hampster-toad.png',
      'ledMode': 'infinite-improbability-drive',
    },
    {
      'name': 'Freak On A Leash',
      'artist': 'Korn',
      'uri': 'spotify:track:6W21LNLz9Sw7sUSNWMSHRu',
      'image': 'assets/tracks/fol.png',
      'ledMode': 'big-brother-glare',
    },
    {
      'name': 'Bella Ciao',
      'artist': 'Italian Fachists',
      'uri': 'spotify:track:3lWzVNe1yFZlkeBBzUuZYu',
      'image': 'assets/tracks/unknown.png',
      'ledMode': 'bokanovsky-burst',
    },
    {
      'name': 'Friesenjung',
      'artist': 'Ski Aggu',
      'uri': 'spotify:track:7b8Z1GU2plJy3aASZTiolF',
      'image': 'assets/tracks/circuit-toad.png',
      'ledMode': 'rainbow-flow',
    },
    {
      'name': 'Cantina Band',
      'artist': 'Star Wars Boogie',
      'uri': 'spotify:track:5ZSAdkQb23NPIcUGt6exdm',
      'image': 'assets/tracks/jedi-toad.png',
      'ledMode': 'bistromathics-surge',
    },
    {
      'name': 'Zombies on Your Lawn',
      'artist': 'Plants vs Zombies',
      'uri': 'spotify:track:4xAoWpiEREH6iMffSDTqTh',
      'image': 'assets/tracks/zombie-toad.png',
      'ledMode': 'soma-haze',
    },
  ];

  String? accessToken;
  String? refreshToken;
  String? currentTrackUri;
  bool isLoading = true;
  bool isUpdating = false;
  bool isPlaying = false;
  double trackPosition = 0.0;
  double trackDuration = 1.0;
  Timer? _progressTimer;
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;
  StreamSubscription? _sub;

  int _tick = 0;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
    initUniLinks();
    checkAuthStatus();
    checkServerAvailability();
  }

  @override
  void dispose() {
    _glowController.dispose();
    _sub?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  Future<void> checkServerAvailability() async {
    if (!mounted) return;
    setState(() => isLoading = true);
    try {
      final response = await http
          .get(Uri.parse('$localServerUrl/mode'))
          .timeout(const Duration(seconds: 2));
      if (response.statusCode == 200) {
        setState(() => serverUrl = localServerUrl);
      } else {
        setState(() => serverUrl = publicServerUrl);
      }
    } catch (e) {
      setState(() => serverUrl = publicServerUrl);
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> updateLedMode(String newMode) async {
    if (!mounted) return;
    try {
      final response = await http
          .post(
            Uri.parse('$serverUrl/update'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'mode': newMode}),
          )
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        _showSnackBar('LED mode updated to $newMode');
      } else {
        _showSnackBar('LED update failed: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('LED connection error: $e');
      if (serverUrl == localServerUrl) {
        setState(() => serverUrl = publicServerUrl);
        await updateLedMode(newMode);
      }
    }
  }

  Future<void> initUniLinks() async {
    if (Platform.isLinux) {
      _showSnackBar(
        'Deep linking not supported on Linux. Test on iOS/Android for Spotify authentication.',
      );
      return;
    }
    final appLinks = AppLinks();
    _sub = appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null && uri.toString().startsWith(redirectUri)) {
          final code = uri.queryParameters['code'];
          if (code != null) {
            exchangeCodeForToken(code);
          } else {
            _showSnackBar('No code found in deep link');
          }
        }
      },
      onError: (err) {
        _showSnackBar('Deep link error: $err');
      },
    );
  }

  Future<void> checkAuthStatus() async {
    setState(() => isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final storedToken = prefs.getString('spotify_access_token');
    final storedRefreshToken = prefs.getString('spotify_refresh_token');
    if (storedToken != null) {
      setState(() {
        accessToken = storedToken;
        refreshToken = storedRefreshToken;
      });
      await fetchCurrentTrack();
    }
    setState(() => isLoading = false);
  }

  Future<void> clearAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('spotify_access_token');
    await prefs.remove('spotify_refresh_token');
    setState(() {
      accessToken = null;
      refreshToken = null;
      isPlaying = false;
      trackPosition = 0.0;
      trackDuration = 1.0;
      _progressTimer?.cancel();
    });
    _showSnackBar('Access token cleared. Please re-authenticate.');
  }

  Future<void> refreshAccessToken() async {
    if (refreshToken == null) {
      _showSnackBar('No refresh token available. Please re-authenticate.');
      return;
    }
    if (clientSecret.isEmpty) {
      _showSnackBar('Client secret required for token refresh');
      return;
    }
    try {
      final response = await http
          .post(
            Uri.parse(spotifyTokenUrl),
            headers: {
              'Content-Type': 'application/x-www-form-urlencoded',
              'Authorization':
                  'Basic ${base64Encode(utf8.encode('$clientId:$clientSecret'))}',
            },
            body: {
              'grant_type': 'refresh_token',
              'refresh_token': refreshToken!,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['access_token'];
        final newRefreshToken = data['refresh_token'] ?? refreshToken;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('spotify_access_token', newToken);
        if (newRefreshToken != null) {
          await prefs.setString('spotify_refresh_token', newRefreshToken);
        }
        setState(() {
          accessToken = newToken;
          refreshToken = newRefreshToken;
        });
        await fetchCurrentTrack();
      } else {
        _showSnackBar('Token refresh failed: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Token refresh error: $e');
    }
  }

  String generateRandomString(int length) {
    const characters =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => characters.codeUnitAt(random.nextInt(characters.length)),
      ),
    );
  }

  String generateCodeChallenge(String codeVerifier) {
    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    return base64Url.encode(digest.bytes).replaceAll('=', '');
  }

  Future<void> authenticate() async {
    final codeVerifier = generateRandomString(128);
    final codeChallenge = generateCodeChallenge(codeVerifier);
    final authUrl = Uri.parse(
      '$spotifyAuthUrl?client_id=$clientId'
      '&response_type=code'
      '&redirect_uri=$redirectUri'
      '&scope=user-read-playback-state%20user-modify-playback-state%20user-read-currently-playing'
      '&code_challenge_method=S256'
      '&code_challenge=$codeChallenge',
    );
    try {
      if (await canLaunchUrl(authUrl)) {
        await launchUrl(authUrl, mode: LaunchMode.externalApplication);
        _codeVerifier = codeVerifier;
      } else {
        _showSnackBar(
          'Cannot launch authentication URL. Please set a default browser.',
        );
      }
    } catch (e) {
      _showSnackBar('Authentication launch error: $e');
    }
  }

  String? _codeVerifier;

  Future<void> exchangeCodeForToken(String code) async {
    if (_codeVerifier == null) {
      _showSnackBar('Code verifier missing');
      return;
    }
    setState(() => isLoading = true);
    try {
      final response = await http
          .post(
            Uri.parse(spotifyTokenUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'client_id': clientId,
              'grant_type': 'authorization_code',
              'code': code,
              'redirect_uri': redirectUri,
              'code_verifier': _codeVerifier!,
            },
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('spotify_access_token', newToken);
        if (newRefreshToken != null) {
          await prefs.setString('spotify_refresh_token', newRefreshToken);
        }
        setState(() {
          accessToken = newToken;
          refreshToken = newRefreshToken;
        });
        await fetchCurrentTrack();
      } else {
        _showSnackBar('Token exchange failed: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Auth error: $e');
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchCurrentTrack() async {
    if (accessToken == null) {
      await refreshAccessToken();
      if (accessToken == null) return;
    }
    try {
      final response = await http
          .get(
            Uri.parse('$spotifyApiUrl/me/player'),
            headers: {'Authorization': 'Bearer $accessToken'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.body.isNotEmpty) {
        final data = jsonDecode(response.body);
        setState(() {
          currentTrackUri = data['item']?['uri'] ?? '';
          isPlaying = data['is_playing'] ?? false;
          trackPosition = (data['progress_ms'] ?? 0).toDouble();
          trackDuration = (data['item']?['duration_ms'] ?? 1).toDouble();
        });
        if (isPlaying && _progressTimer == null) {
          _startProgressTimer();
        }
      } else if (response.statusCode == 204) {
        setState(() {
          currentTrackUri = '';
          isPlaying = false;
          trackPosition = 0.0;
          trackDuration = 1.0;
          _progressTimer?.cancel();
        });
      } else {
        _showSnackBar('Failed to fetch track: ${response.statusCode}');
      }
    } catch (e) {
      _showSnackBar('Connection error: $e');
    }
  }

  Future<String?> getActiveDevice() async {
    if (accessToken == null) {
      await refreshAccessToken();
      if (accessToken == null) return null;
    }
    try {
      var response = await http
          .get(
            Uri.parse('$spotifyApiUrl/me/player/devices'),
            headers: {'Authorization': 'Bearer $accessToken'},
          )
          .timeout(const Duration(seconds: 15));
      var devices = <dynamic>[];
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        devices = data['devices'] as List<dynamic>;
      } else {
        _showSnackBar('Failed to fetch devices: ${response.statusCode}');
        return null;
      }

      if (devices.isEmpty) {
        final spotifyUri = Uri.parse('spotify://');
        if (await canLaunchUrl(spotifyUri)) {
          await launchUrl(spotifyUri, mode: LaunchMode.externalApplication);
          await Future.delayed(
            const Duration(seconds: 3),
          ); // Give time for Spotify to launch and register
          response = await http
              .get(
                Uri.parse('$spotifyApiUrl/me/player/devices'),
                headers: {'Authorization': 'Bearer $accessToken'},
              )
              .timeout(const Duration(seconds: 15));
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            devices = data['devices'] as List<dynamic>;
          } else {
            _showSnackBar(
              'Failed to fetch devices after launch: ${response.statusCode}',
            );
            return null;
          }
        } else {
          _showSnackBar('Cannot launch Spotify app');
          return null;
        }
      }

      if (devices.isEmpty) {
        _showSnackBar('No Spotify devices found even after launching the app');
        return null;
      }

      final activeDevice = devices.firstWhere(
        (device) => device['is_active'] == true,
        orElse: () => devices[0],
      );
      return activeDevice['id'] as String?;
    } catch (e) {
      _showSnackBar('Error fetching devices: $e');
      return null;
    }
  }

  Future<void> playTrack(String trackUri, String ledMode) async {
    if (accessToken == null) {
      _showSnackBar('Please authenticate with Spotify first');
      await refreshAccessToken();
      if (accessToken == null) {
        setState(() => isLoading = false);
        return;
      }
    }
    setState(() {
      isLoading = true;
      isUpdating = true;
    });
    try {
      final deviceId = await getActiveDevice();
      if (deviceId == null) {
        _showSnackBar(
          'No active Spotify device found. Please open the Spotify app and play a track briefly.',
        );
        setState(() {
          isLoading = false;
          isUpdating = false;
        });
        return;
      }
      final response = await http
          .put(
            Uri.parse('$spotifyApiUrl/me/player/play?device_id=$deviceId'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'uris': [trackUri],
            }),
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 204) {
        setState(() {
          currentTrackUri = trackUri;
          isLoading = false;
          isUpdating = false;
          isPlaying = true;
        });
        await fetchCurrentTrack();
        await updateLedMode(ledMode); // Set LED mode
        _startProgressTimer();
        _showSnackBar(
          'Playing ${tracks.firstWhere((t) => t['uri'] == trackUri)['name']}',
        );
      } else if (response.statusCode == 401) {
        _showSnackBar('Access token expired. Refreshing...');
        await refreshAccessToken();
        if (accessToken != null) {
          await playTrack(trackUri, ledMode);
        } else {
          _showSnackBar('Failed to refresh token. Please re-authenticate.');
          setState(() {
            isLoading = false;
            isUpdating = false;
          });
        }
      } else {
        _showSnackBar('Playback failed: ${response.statusCode}');
        setState(() {
          isLoading = false;
          isUpdating = false;
        });
      }
    } catch (e) {
      _showSnackBar('Playback error: $e');
      setState(() {
        isLoading = false;
        isUpdating = false;
      });
    }
  }

  Future<void> togglePlayPause() async {
    if (accessToken == null || currentTrackUri == null) {
      _showSnackBar('Please select a track and authenticate');
      return;
    }
    setState(() => isLoading = true);
    try {
      final deviceId = await getActiveDevice();
      if (deviceId == null) {
        _showSnackBar(
          'No active Spotify device found. Please open the Spotify app and play a track briefly.',
        );
        setState(() => isLoading = false);
        return;
      }
      final response = await http
          .put(
            Uri.parse(
              isPlaying
                  ? '$spotifyApiUrl/me/player/pause?device_id=$deviceId'
                  : '$spotifyApiUrl/me/player/play?device_id=$deviceId',
            ),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
            body: '{}',
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 204) {
        setState(() {
          isPlaying = !isPlaying;
          isLoading = false;
          if (!isPlaying) {
            _progressTimer?.cancel();
          } else {
            _startProgressTimer();
          }
        });
        _showSnackBar(isPlaying ? 'Resumed playback' : 'Paused playback');
        await fetchCurrentTrack(); // Sync state
      } else if (response.statusCode == 401) {
        _showSnackBar('Access token expired. Refreshing...');
        await refreshAccessToken();
        if (accessToken != null) {
          await togglePlayPause();
        } else {
          _showSnackBar('Failed to refresh token. Please re-authenticate.');
          setState(() => isLoading = false);
        }
      } else {
        _showSnackBar('Toggle playback failed: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Toggle playback error: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> seekToPosition(double positionMs) async {
    if (accessToken == null || currentTrackUri == null) {
      _showSnackBar('Please select a track and authenticate');
      return;
    }
    setState(() => isLoading = true);
    try {
      final deviceId = await getActiveDevice();
      if (deviceId == null) {
        _showSnackBar(
          'No active Spotify device found. Please open the Spotify app and play a track briefly.',
        );
        setState(() => isLoading = false);
        return;
      }
      final response = await http
          .put(
            Uri.parse(
              '$spotifyApiUrl/me/player/seek?position_ms=${positionMs.round()}&device_id=$deviceId',
            ),
            headers: {'Authorization': 'Bearer $accessToken'},
          )
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 204) {
        setState(() {
          trackPosition = positionMs;
          isLoading = false;
        });
        if (isPlaying) {
          _startProgressTimer();
        }
      } else if (response.statusCode == 401) {
        _showSnackBar('Access token expired. Refreshing...');
        await refreshAccessToken();
        if (accessToken != null) {
          await seekToPosition(positionMs);
        } else {
          _showSnackBar('Failed to refresh token. Please re-authenticate.');
          setState(() => isLoading = false);
        }
      } else {
        _showSnackBar('Seek failed: ${response.statusCode}');
        setState(() => isLoading = false);
      }
    } catch (e) {
      _showSnackBar('Seek error: $e');
      setState(() => isLoading = false);
    }
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _tick = 0;
    _progressTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isPlaying && mounted) {
        _tick++;
        setState(() {
          trackPosition += 1000;
          if (trackPosition >= trackDuration) {
            trackPosition = trackDuration;
            isPlaying = false;
            timer.cancel();
          }
        });
        if (_tick % 5 == 0) {
          fetchCurrentTrack(); // Periodically sync with actual Spotify state to prevent drift
        }
      }
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.orbitron(
            color: Theme.of(context).textTheme.bodyLarge!.color,
            fontSize: 14,
          ),
        ),
        backgroundColor: Theme.of(
          context,
        ).scaffoldBackgroundColor.withOpacity(0.8),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatDuration(double ms) {
    final seconds = (ms / 1000).floor();
    final minutes = (seconds / 60).floor();
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String titleCase(String text) {
    return text
        .split('-')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).scaffoldBackgroundColor.withOpacity(0.9),
            Theme.of(context).colorScheme.surface.withOpacity(0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child:
                Theme.of(context).scaffoldBackgroundColor ==
                    const Color(0xFF1C2526)
                ? const SpookyField()
                : const StarField(opacity: 0.3),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Galactic Tunes',
                            style: GoogleFonts.orbitron(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge!.color,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (accessToken == null)
                                ElevatedButton(
                                  onPressed: authenticate,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        Theme.of(context).primaryColor ??
                                        Colors.blue,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: const Size(100, 36),
                                  ),
                                  child: Text(
                                    'Login to Spotify',
                                    style: GoogleFonts.orbitron(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge!.color,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              if (accessToken != null)
                                ElevatedButton(
                                  onPressed: clearAccessToken,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    minimumSize: const Size(100, 36),
                                  ),
                                  child: Text(
                                    'Clear Token',
                                    style: GoogleFonts.orbitron(
                                      color: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge!.color,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: isLoading
                          ? Center(
                              child: CircularProgressIndicator(
                                color:
                                    Theme.of(context).primaryColor ??
                                    Colors.blue,
                              ),
                            )
                          : ListView(
                              padding: const EdgeInsets.all(12),
                              children: [
                                ClipRect(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 3,
                                      sigmaY: 3,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.surface.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Theme.of(context)
                                              .textTheme
                                              .bodyLarge!
                                              .color!
                                              .withOpacity(0.3),
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              AnimatedBuilder(
                                                animation: _glowAnimation,
                                                builder: (context, child) {
                                                  return Container(
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color: Theme.of(context)
                                                              .primaryColor
                                                              .withOpacity(
                                                                0.4 *
                                                                    _glowAnimation
                                                                        .value,
                                                              ),
                                                          blurRadius:
                                                              8 *
                                                              _glowAnimation
                                                                  .value,
                                                          spreadRadius:
                                                              2 *
                                                              _glowAnimation
                                                                  .value,
                                                        ),
                                                      ],
                                                    ),
                                                    child:
                                                        currentTrackUri !=
                                                                null &&
                                                            currentTrackUri!
                                                                .isNotEmpty
                                                        ? Image.asset(
                                                            tracks.firstWhere(
                                                              (track) =>
                                                                  track['uri'] ==
                                                                  currentTrackUri,
                                                              orElse: () => {
                                                                'image':
                                                                    'assets/tracks/unknown.png',
                                                              },
                                                            )['image']!,
                                                            width: 60,
                                                            height: 60,
                                                            fit: BoxFit.cover,
                                                            errorBuilder:
                                                                (
                                                                  context,
                                                                  error,
                                                                  stackTrace,
                                                                ) {
                                                                  return Icon(
                                                                    Icons
                                                                        .image_not_supported,
                                                                    color: Theme.of(context)
                                                                        .textTheme
                                                                        .bodyLarge!
                                                                        .color,
                                                                    size: 60,
                                                                  );
                                                                },
                                                          )
                                                        : Icon(
                                                            Icons.music_note,
                                                            color:
                                                                Theme.of(
                                                                      context,
                                                                    )
                                                                    .textTheme
                                                                    .bodyLarge!
                                                                    .color,
                                                            size: 60,
                                                          ),
                                                  );
                                                },
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: Text(
                                                  currentTrackUri != null &&
                                                          currentTrackUri!
                                                              .isNotEmpty
                                                      ? 'Playing: ${tracks.firstWhere((track) => track['uri'] == currentTrackUri, orElse: () => {'name': 'Unknown'})['name']}'
                                                      : 'No track playing',
                                                  style: GoogleFonts.orbitron(
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge!
                                                        .color,
                                                    fontSize: 14,
                                                  ),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  maxLines: 2,
                                                ),
                                              ),
                                            ],
                                          ),
                                          if (currentTrackUri != null &&
                                              currentTrackUri!.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  icon: Icon(
                                                    isPlaying
                                                        ? Icons.pause
                                                        : Icons.play_arrow,
                                                    color: Theme.of(context)
                                                        .textTheme
                                                        .bodyLarge!
                                                        .color,
                                                  ),
                                                  onPressed: togglePlayPause,
                                                ),
                                              ],
                                            ),
                                            Slider(
                                              value: trackPosition,
                                              min: 0.0,
                                              max: trackDuration,
                                              onChanged: (value) {
                                                setState(() {
                                                  trackPosition = value;
                                                });
                                              },
                                              onChangeEnd: (value) {
                                                seekToPosition(value);
                                              },
                                              activeColor: Theme.of(
                                                context,
                                              ).primaryColor,
                                              inactiveColor: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .color!
                                                  .withOpacity(0.3),
                                            ),
                                            Text(
                                              '${_formatDuration(trackPosition)} / ${_formatDuration(trackDuration)}',
                                              style: GoogleFonts.orbitron(
                                                color: Theme.of(
                                                  context,
                                                ).textTheme.bodyLarge!.color,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ClipRect(
                                  child: BackdropFilter(
                                    filter: ImageFilter.blur(
                                      sigmaX: 3,
                                      sigmaY: 3,
                                    ),
                                    child: AnimatedBuilder(
                                      animation: _glowAnimation,
                                      builder: (context, child) {
                                        return Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .surface
                                                .withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            border: Border.all(
                                              color: Theme.of(context)
                                                  .textTheme
                                                  .bodyLarge!
                                                  .color!
                                                  .withOpacity(0.3),
                                            ),
                                          ),
                                          child: Text(
                                            'Select Track',
                                            style: GoogleFonts.orbitron(
                                              color: Theme.of(
                                                context,
                                              ).textTheme.bodyLarge!.color,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                LayoutBuilder(
                                  builder: (context, gridConstraints) {
                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      gridDelegate:
                                          const SliverGridDelegateWithFixedCrossAxisCount(
                                            crossAxisCount: 2,
                                            crossAxisSpacing: 8,
                                            mainAxisSpacing: 8,
                                            childAspectRatio: 1.0,
                                          ),
                                      itemCount: tracks.length,
                                      itemBuilder: (context, index) {
                                        final track = tracks[index];
                                        final isEnabled =
                                            !(isUpdating ||
                                                accessToken == null);
                                        return Material(
                                          color: Colors.transparent,
                                          child: InkWell(
                                            onTap: isEnabled
                                                ? () => playTrack(
                                                    track['uri']!,
                                                    track['ledMode']!,
                                                  )
                                                : null,
                                            splashColor: Theme.of(
                                              context,
                                            ).primaryColor.withOpacity(0.3),
                                            highlightColor: isEnabled
                                                ? Theme.of(context).primaryColor
                                                      .withOpacity(0.2)
                                                : Colors.grey.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .surface
                                                    .withOpacity(
                                                      isEnabled ? 0.2 : 0.1,
                                                    ),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                border: Border.all(
                                                  color:
                                                      track['uri'] ==
                                                          currentTrackUri
                                                      ? Theme.of(context)
                                                            .primaryColor
                                                            .withOpacity(
                                                              0.8 *
                                                                  _glowAnimation
                                                                      .value,
                                                            )
                                                      : Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge!
                                                            .color!
                                                            .withOpacity(0.3),
                                                ),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color:
                                                        track['uri'] ==
                                                            currentTrackUri
                                                        ? Theme.of(context)
                                                              .primaryColor
                                                              .withOpacity(
                                                                0.4 *
                                                                    _glowAnimation
                                                                        .value,
                                                              )
                                                        : Theme.of(context)
                                                              .scaffoldBackgroundColor
                                                              .withOpacity(0.3),
                                                    blurRadius:
                                                        8 *
                                                        _glowAnimation.value,
                                                    spreadRadius:
                                                        2 *
                                                        _glowAnimation.value,
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
                                                            6,
                                                          ),
                                                      child: Image.asset(
                                                        track['image']!,
                                                        width:
                                                            gridConstraints
                                                                    .maxWidth /
                                                                2 -
                                                            18,
                                                        height:
                                                            (gridConstraints
                                                                    .maxWidth /
                                                                2 -
                                                            18),
                                                        fit: BoxFit.contain,
                                                        errorBuilder:
                                                            (
                                                              context,
                                                              error,
                                                              stackTrace,
                                                            ) {
                                                              return Icon(
                                                                Icons
                                                                    .image_not_supported,
                                                                color:
                                                                    Theme.of(
                                                                          context,
                                                                        )
                                                                        .textTheme
                                                                        .bodyLarge!
                                                                        .color,
                                                                size: 60,
                                                              );
                                                            },
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  Flexible(
                                                    child: Padding(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 6,
                                                          ),
                                                      child: Text(
                                                        '${track['name']}\n${track['artist']}',
                                                        textAlign:
                                                            TextAlign.center,
                                                        style: GoogleFonts.orbitron(
                                                          color:
                                                              track['uri'] ==
                                                                  currentTrackUri
                                                              ? Theme.of(
                                                                      context,
                                                                    )
                                                                    .textTheme
                                                                    .bodyLarge!
                                                                    .color
                                                              : Theme.of(
                                                                      context,
                                                                    )
                                                                    .textTheme
                                                                    .bodyLarge!
                                                                    .color!
                                                                    .withOpacity(
                                                                      isEnabled
                                                                          ? 0.7
                                                                          : 0.4,
                                                                    ),
                                                          fontSize: 10,
                                                        ),
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        maxLines: 2,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                ],
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                              ],
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
