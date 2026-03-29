import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';

// ============================================================================
// 🔹 1. THE POLYMORPHIC MEDIA ARCHITECTURE
// ============================================================================

abstract class MomentMedia {
  Widget buildPreview(BuildContext context);
  Widget buildExpanded(BuildContext context);

  factory MomentMedia.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    if (type == 'photo') return PhotoMedia(json['url']);
    if (type == 'text') return TextMedia(json['text']);
    if (type == 'poll')
      return PollMedia(
        json['question'] ?? 'Poll',
        List<String>.from(json['options'] ?? []),
      );
    if (type == 'audio')
      return AudioMedia(
        json['title'] ?? 'Voice Note',
        json['duration'] ?? '0:00',
        json['url'] ?? '',
      );
    if (type == 'music') {
      return MusicMedia(
        json['song_title'] ?? 'Unknown Song',
        json['artist'] ?? 'Unknown Artist',
        json['album_art'] ?? '',
        json['preview_url'] ?? '',
        json['platform_links'] ?? {},
      );
    }
    return UnknownMedia();
  }
}

class PhotoMedia implements MomentMedia {
  final String url;
  PhotoMedia(this.url);

  @override
  Widget buildPreview(BuildContext context) =>
      Image.network(url, fit: BoxFit.cover);

  @override
  Widget buildExpanded(BuildContext context) =>
      Image.network(url, fit: BoxFit.cover, width: double.infinity);
}

class TextMedia implements MomentMedia {
  final String text;
  TextMedia(this.text);

  @override
  Widget buildPreview(BuildContext context) {
    return Container(
      color: const Color(0xFFE8E5D9),
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          maxLines: 4,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  @override
  Widget buildExpanded(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8E5D9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        physics: const BouncingScrollPhysics(),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class PollMedia implements MomentMedia {
  final String question;
  final List<String> options;
  PollMedia(this.question, this.options);

  @override
  Widget buildPreview(BuildContext context) {
    return Container(
      color: const Color(0xFF3A5A78),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.poll_rounded, color: Colors.white54, size: 40),
          const SizedBox(height: 12),
          Text(
            question,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget buildExpanded(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFF3A5A78),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              question,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 32),
            for (String option in options)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 16,
                ),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    option,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// 🔹 1. UPDATE THE MEDIA CLASSES TO ACCEPT URLS
class MusicMedia implements MomentMedia {
  final String songTitle;
  final String artist;
  final String albumArtUrl;
  final String previewUrl;
  final Map<String, dynamic> platformLinks;

  MusicMedia(
    this.songTitle,
    this.artist,
    this.albumArtUrl,
    this.previewUrl,
    this.platformLinks,
  );

  @override
  Widget buildPreview(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: NetworkImage(albumArtUrl),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        color: Colors.black.withOpacity(0.4),
        child: const Center(
          child: Icon(Icons.music_note, color: Colors.white, size: 48),
        ),
      ),
    );
  }

  @override
  Widget buildExpanded(BuildContext context) {
    return SpinningVinylPlayer(
      songTitle: songTitle,
      artist: artist,
      albumArtUrl: albumArtUrl,
      previewUrl: previewUrl,
      platformLinks: platformLinks,
    );
  }
}

class AudioMedia implements MomentMedia {
  final String title;
  final String duration;
  final String audioUrl; // 🔹 Added so the cassette can play!

  AudioMedia(this.title, this.duration, this.audioUrl);

  @override
  Widget buildPreview(BuildContext context) {
    return Container(
      color: const Color(0xFFD35400),
      child: const Center(
        child: Icon(Icons.mic_rounded, color: Colors.white, size: 48),
      ),
    );
  }

  @override
  Widget buildExpanded(BuildContext context) {
    return CassetteTapePlayer(
      title: title,
      duration: duration,
      audioUrl: audioUrl,
    );
  }
}

class UnknownMedia implements MomentMedia {
  @override
  Widget buildPreview(BuildContext context) =>
      Container(color: Colors.grey[300]);
  @override
  Widget buildExpanded(BuildContext context) =>
      const SizedBox(height: 200, child: Center(child: Icon(Icons.error)));
}

// ============================================================================
// 🔹 2. THE INTERACTIVE PLAYERS (Stateful Widgets for Animation)
// ============================================================================

// 🔹 THE UPGRADED VINYL PLAYER (With Odesli Deep Links)
class SpinningVinylPlayer extends StatefulWidget {
  final String songTitle;
  final String artist;
  final String albumArtUrl;
  final String previewUrl;
  final Map<String, dynamic> platformLinks;

  const SpinningVinylPlayer({
    super.key,
    required this.songTitle,
    required this.artist,
    required this.albumArtUrl,
    required this.previewUrl,
    required this.platformLinks,
  });

  @override
  State<SpinningVinylPlayer> createState() => _SpinningVinylPlayerState();
}

class _SpinningVinylPlayerState extends State<SpinningVinylPlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AudioPlayer _audioPlayer = AudioPlayer(); // 🔹 just_audio Engine
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setUrl(widget.previewUrl);

      // Listen for the exact moment the stream finishes
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() {
            _isPlaying = false;
            _controller.stop();
            _audioPlayer.seek(Duration.zero); // Reset needle to start
          });
        }
      });
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose(); // Instantly kills audio when screen is swiped away
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.repeat();
        _audioPlayer.play();
      } else {
        _controller.stop();
        _audioPlayer.pause();
      }
    });
  }

  Future<void> _launchStreamingApp(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication))
        debugPrint("Could not launch $url");
    } catch (e) {
      debugPrint("Error launching app: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E1366), Color(0xFF0A0626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) => Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: child,
                  ),
                  child: Container(
                    width: 220,
                    height: 220,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFF111111),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                      border: Border.all(color: Colors.white12, width: 2),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 190,
                          height: 190,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white10, width: 1),
                          ),
                        ),
                        Container(
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white10, width: 1),
                          ),
                        ),
                        ClipOval(
                          child: SizedBox(
                            width: 90,
                            height: 90,
                            child: widget.albumArtUrl.isNotEmpty
                                ? Image.network(
                                    widget.albumArtUrl,
                                    fit: BoxFit.cover,
                                  )
                                : Container(color: Colors.redAccent),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isPlaying
                          ? Colors.transparent
                          : Colors.black.withOpacity(0.5),
                    ),
                    child: Center(
                      child: _isPlaying
                          ? const SizedBox()
                          : const Icon(
                              Icons.play_arrow_rounded,
                              color: Colors.white,
                              size: 48,
                            ),
                    ),
                  ),
                ),
                IgnorePointer(
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              widget.songTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.artist,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),
            const SizedBox(height: 48),
            if (widget.platformLinks.isNotEmpty) ...[
              const Text(
                "Listen to full song on:",
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: widget.platformLinks.entries
                    .map(
                      (entry) => _buildPlatformButton(entry.key, entry.value),
                    )
                    .toList(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformButton(String platformName, String url) {
    IconData icon;
    Color color;
    switch (platformName.toLowerCase()) {
      case 'spotify':
        icon = Icons.library_music;
        color = const Color(0xFF1DB954);
        break;
      case 'apple music':
      case 'apple':
        icon = Icons.music_note;
        color = const Color(0xFFFA243C);
        break;
      case 'youtube':
        icon = Icons.play_circle_filled;
        color = const Color(0xFFFF0000);
        break;
      default:
        icon = Icons.link;
        color = Colors.white70;
    }
    return GestureDetector(
      onTap: () => _launchStreamingApp(url),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(
              platformName.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CassetteTapePlayer extends StatefulWidget {
  final String title;
  final String duration;
  final String audioUrl;

  const CassetteTapePlayer({
    super.key,
    required this.title,
    required this.duration,
    required this.audioUrl,
  });

  @override
  State<CassetteTapePlayer> createState() => _CassetteTapePlayerState();
}

class _CassetteTapePlayerState extends State<CassetteTapePlayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final AudioPlayer _audioPlayer = AudioPlayer(); // 🔹 just_audio Engine
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    _initAudio();
  }

  Future<void> _initAudio() async {
    try {
      await _audioPlayer.setUrl(widget.audioUrl);
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() {
            _isPlaying = false;
            _controller.stop();
            _audioPlayer.seek(Duration.zero);
          });
        }
      });
    } catch (e) {
      debugPrint("Error loading audio: $e");
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() {
    HapticFeedback.lightImpact();
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.repeat();
        _audioPlayer.play();
      } else {
        _controller.stop();
        _audioPlayer.pause();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: const Color(0xFFE8E5D9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: 280,
              height: 180,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFD35400),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 10),
                  ),
                ],
                border: Border.all(color: Colors.black12, width: 2),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontFamily: 'Courier',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 160,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (_, child) => Transform.rotate(
                            angle: _controller.value * 2 * math.pi,
                            child: child,
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                        AnimatedBuilder(
                          animation: _controller,
                          builder: (_, child) => Transform.rotate(
                            angle: _controller.value * 2 * math.pi,
                            child: child,
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            ),
            const SizedBox(height: 40),
            Text(
              widget.duration,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: _togglePlay,
                  child: Icon(
                    _isPlaying
                        ? Icons.pause_circle_filled
                        : Icons.play_circle_fill,
                    color: const Color(0xFFD35400),
                    size: 80,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 🔹 3. THE REFACTORED DATA MODEL
// ============================================================================
class Moment {
  final String id;
  final String authorName;
  final String avatarUrl;
  final DateTime timestamp;
  final MomentMedia media;
  final String emotionEmoji;

  Moment({
    required this.id,
    required this.authorName,
    required this.avatarUrl,
    required this.timestamp,
    required Map<String, dynamic> payload,
    required this.emotionEmoji,
  }) : media = MomentMedia.fromJson(payload);
}

// ============================================================================
// 🔹 4. THE SPOT DISPLAY SCREEN
// ============================================================================
class SpotDisplayScreen extends StatefulWidget {
  final String spotTitle;

  const SpotDisplayScreen({super.key, required this.spotTitle});

  @override
  State<SpotDisplayScreen> createState() => _SpotDisplayScreenState();
}

class _SpotDisplayScreenState extends State<SpotDisplayScreen> {
  late PageController _stageController;
  late ScrollController _timelineController;

  int _currentIndex = 0;
  bool _isDraggingTimeline = false;
  final double _nodeWidth = 80.0;

  // --- EXPANDED DUMMY DATA WITH ALL TYPES ---
  final List<Moment> _moments = [
    Moment(
      id: '1',
      authorName: 'David L.',
      avatarUrl: 'https://i.pravatar.cc/150?u=david',
      timestamp: DateTime(2022, 5, 12),
      emotionEmoji: '☕',
      payload: {
        'type': 'photo',
        'url':
            'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=800&q=80',
      },
    ),
    Moment(
      id: '2',
      authorName: 'Maya T.',
      avatarUrl: 'https://i.pravatar.cc/150?u=maya',
      timestamp: DateTime(2023, 8, 22),
      emotionEmoji: '🎙️',
      payload: {
        'type': 'audio',
        'title': 'Morning Rain Sounds',
        'duration': '1:45',
        'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      }, // 🔹 CASSETTE TAPE!
    ),
    Moment(
      id: '3',
      authorName: 'Alex M.',
      avatarUrl: 'https://i.pravatar.cc/150?u=alex',
      timestamp: DateTime(2024, 1, 15),
      emotionEmoji: '🎶',
      payload: {
        'type': 'music',
        'song_title': 'Midnight City',
        'artist': 'M83',
        'album_art':
            'https://images.unsplash.com/photo-1619983081563-430f63602796?w=800&q=80',
        // 🔹 REAL WORKING AUDIO LINK: Replaced the dummy URL with a live MP3 stream
        'preview_url':
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        'platform_links': {
          'Spotify': 'https://open.spotify.com/track/1234',
          'Apple Music': 'https://music.apple.com/us/album/1234',
          'YouTube': 'https://youtube.com/watch?v=1234',
        },
      },
    ),
    Moment(
      id: '4',
      authorName: 'Sarah J.',
      avatarUrl: 'https://i.pravatar.cc/150?u=sarah',
      timestamp: DateTime(2025, 10, 15),
      emotionEmoji: '🔥',
      payload: {
        'type': 'poll',
        'question': 'Best time to visit this spot?',
        'options': ['Sunrise', 'Sunset', 'Midnight'],
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = _moments.length - 1;
    _stageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.80,
    );
    _timelineController = ScrollController(
      initialScrollOffset: _currentIndex * _nodeWidth,
    );
  }

  @override
  void dispose() {
    _stageController.dispose();
    _timelineController.dispose();
    super.dispose();
  }

  void _onStagePageChanged(int index) {
    if (_currentIndex != index) {
      HapticFeedback.selectionClick();
      setState(() => _currentIndex = index);
    }

    if (!_isDraggingTimeline && _timelineController.hasClients) {
      _timelineController.animateTo(
        index * _nodeWidth,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  void _openMomentFullScreen(Moment moment) {
    HapticFeedback.lightImpact();
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        transitionDuration: const Duration(milliseconds: 350),
        reverseTransitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, animation, secondaryAnimation) =>
            MomentFullScreenView(moment: moment),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF2),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),

              SizedBox(
                height: 420,
                child: PageView.builder(
                  controller: _stageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: _onStagePageChanged,
                  itemCount: _moments.length,
                  itemBuilder: (context, index) {
                    return _buildPolaroidCard(_moments[index], index);
                  },
                ),
              ),

              const SizedBox(height: 24),
              _buildTimeScrubber(),
              const SizedBox(height: 48),
              _buildCuratedSections(),
              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.black87,
                  size: 24,
                ),
              ),
              const Row(
                children: [
                  Icon(Icons.public, color: Colors.black54, size: 16),
                  SizedBox(width: 4),
                  Text(
                    "Public",
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  widget.spotTitle,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87,
                    letterSpacing: -0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(
                Icons.bookmark_border,
                color: Colors.black87,
                size: 32,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(height: 2, width: double.infinity, color: Colors.black87),
        ],
      ),
    );
  }

  Widget _buildPolaroidCard(Moment moment, int index) {
    return AnimatedBuilder(
      animation: _stageController,
      builder: (context, child) {
        double pageOffset = 0;
        if (_stageController.position.haveDimensions) {
          pageOffset =
              (_stageController.page ?? _currentIndex.toDouble()) - index;
        } else {
          pageOffset = (_currentIndex - index).toDouble();
        }

        double scale = (1 - (pageOffset.abs() * 0.15)).clamp(0.85, 1.0);
        double opacity = (1 - (pageOffset.abs() * 0.5)).clamp(0.5, 1.0);

        return Transform.scale(
          scale: scale,
          child: Opacity(opacity: opacity, child: child),
        );
      },
      child: GestureDetector(
        onTap: () => _openMomentFullScreen(moment),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          alignment: Alignment.center,
          child: AspectRatio(
            aspectRatio: 0.75,
            child: Hero(
              tag: 'moment_card_${moment.id}',
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              moment.media.buildPreview(context),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black12,
                                        blurRadius: 4,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.diamond_outlined,
                                    color: Colors.blueAccent,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundImage: NetworkImage(moment.avatarUrl),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              moment.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            moment.emotionEmoji,
                            style: const TextStyle(fontSize: 22),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeScrubber() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(width: 30, height: 2, color: Colors.grey[400]),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
                "Scroll Through Time",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black54,
                  fontSize: 16,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Container(width: 30, height: 2, color: Colors.grey[400]),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 100,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final double sidePadding =
                  (constraints.maxWidth / 2) - (_nodeWidth / 2);

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollStartNotification) {
                        _isDraggingTimeline = true;
                      } else if (notification is ScrollUpdateNotification) {
                        if (_isDraggingTimeline) {
                          int newIndex =
                              (_timelineController.offset / _nodeWidth).round();
                          newIndex = newIndex.clamp(0, _moments.length - 1);
                          if (newIndex != _currentIndex) {
                            HapticFeedback.selectionClick();
                            setState(() => _currentIndex = newIndex);
                            _stageController.jumpToPage(newIndex);
                          }
                        }
                      } else if (notification is ScrollEndNotification) {
                        _isDraggingTimeline = false;
                        Future.microtask(() {
                          if (_timelineController.hasClients) {
                            _timelineController.animateTo(
                              _currentIndex * _nodeWidth,
                              duration: const Duration(milliseconds: 200),
                              curve: Curves.easeOutCubic,
                            );
                          }
                        });
                      }
                      return true;
                    },
                    child: ListView.builder(
                      controller: _timelineController,
                      scrollDirection: Axis.horizontal,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: sidePadding),
                      itemCount: _moments.length,
                      itemBuilder: (context, index) {
                        return SizedBox(
                          width: _nodeWidth,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 2,
                                color: Colors.grey[400],
                                margin: EdgeInsets.only(
                                  left: index == 0 ? _nodeWidth / 2 : 0,
                                  right: index == _moments.length - 1
                                      ? _nodeWidth / 2
                                      : 0,
                                ),
                              ),
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.grey[500],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFBFBF2),
                                    width: 2,
                                  ),
                                ),
                              ),
                              if (index == 0)
                                Positioned(
                                  top: 10,
                                  child: Text(
                                    _moments.first.timestamp.year.toString(),
                                    style: const TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if (index == _moments.length - 1)
                                const Positioned(
                                  top: 10,
                                  child: Text(
                                    "Now",
                                    style: TextStyle(
                                      color: Colors.black54,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  IgnorePointer(
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF91C5F2).withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: const Color(0xFF91C5F2),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    child: IgnorePointer(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _formatDate(_moments[_currentIndex].timestamp),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 2, bottom: 4),
                            width: 80,
                            height: 1.5,
                            color: Colors.black87,
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: Colors.black87,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCuratedSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "The Soundtrack",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                width: 120,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: const DecorationImage(
                    image: NetworkImage(
                      "https://images.unsplash.com/photo-1614613535308-eb5fbd3d2c17?w=300&q=80",
                    ),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  alignment: Alignment.bottomLeft,
                  child: const Text(
                    "Track Name",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 40),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            "The Vibe Check",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Row(
            children: [
              _buildVibePill("☕ Cozy", "45%"),
              const SizedBox(width: 12),
              _buildVibePill("🎶 Loud", "30%"),
              const SizedBox(width: 12),
              _buildVibePill("🌧️ Chill", "25%"),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVibePill(String emojiText, String percentage) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              emojiText,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              percentage,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.blueAccent[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 🔹 THE FULL SCREEN VIEW
// ============================================================================
class MomentFullScreenView extends StatelessWidget {
  final Moment moment;

  const MomentFullScreenView({super.key, required this.moment});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Text(
                    moment.emotionEmoji,
                    style: const TextStyle(fontSize: 28),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Hero(
                  tag: 'moment_card_${moment.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: moment.media.buildExpanded(context)),
                          Container(
                            padding: const EdgeInsets.all(20),
                            color: Colors.white,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundImage: NetworkImage(
                                    moment.avatarUrl,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        moment.authorName,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "Added a new memory here",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Add a comment...",
                          style: TextStyle(color: Colors.white54, fontSize: 15),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.favorite_border,
                    color: Colors.white,
                    size: 28,
                  ),
                  const SizedBox(width: 16),
                  const Icon(
                    Icons.share_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
