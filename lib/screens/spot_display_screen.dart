import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';
import 'package:spots_app/utils/models.dart';
import 'package:spots_app/components/overlapping_reaction_stack.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';

// Helper to format large numbers (e.g., 145000 -> 145K)
// String formatReactionsCount(int count) {
//   if (count >= 1000) {
//     return '${(count / 1000).toStringAsFixed(count % 1000 == 0 ? 0 : 1)}K';
//   }
//   return count.toString();
// }

String formatNumberWithCommas(int count) {
  var formatter = NumberFormat('#,###,###');
  return formatter.format(count);
}

// ============================================================================
// 🔹 2. THE POLYMORPHIC MEDIA ARCHITECTURE
// ============================================================================
abstract class MomentMedia {
  Widget buildPreview(BuildContext context);
  Widget buildExpanded(BuildContext context);

  factory MomentMedia.fromJson(Map<String, dynamic> json) {
    final type = json['type'];
    if (type == 'photo') {
      return PhotoMedia(json['url']);
    }
    if (type == 'text') {
      return TextMedia(json['text']);
    }
    if (type == 'poll') {
      return PollMedia(
        json['question'] ?? 'Poll',
        List<String>.from(json['options'] ?? []),
      );
    }
    if (type == 'audio') {
      return AudioMedia(
        json['title'] ?? 'Voice Note',
        json['duration'] ?? '0:00',
        json['url'] ?? '',
      );
    }
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
      // color: const Color(0xFFE8E5D9),
      color: const Color(0xFFFFF3A9),
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
      //color: const Color(0xFFE8E5D9),
      color: const Color(0xFFFFF3A9),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(), // Main card scrolls
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              text,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
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
        physics: const NeverScrollableScrollPhysics(), // Main card scrolls
        padding: const EdgeInsets.all(32),
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
  final String audioUrl;
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
// 🔹 3. INTERACTIVE AUDIO PLAYERS
// ============================================================================

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
  final AudioPlayer _audioPlayer = AudioPlayer();
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
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() {
            _isPlaying = false;
            _controller.stop();
            _audioPlayer.seek(Duration.zero);
          });
        }
      });
    } catch (e) {}
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

  Future<void> _launchStreamingApp(String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication))
        debugPrint("Could not launch $url");
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          // colors: [Color(0xFF1E1366), Color(0xFF0A0626)],
          colors: [Color(0xFF304F8C), Color(0xFFD91E63), Color(0xFF1E1366)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        physics:
            const NeverScrollableScrollPhysics(), // Allows main card to scroll seamlessly
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                // ==========================================
                // 1. THE SPINNING BLACK VINYL & GROOVES
                // ==========================================
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
                      ],
                    ),
                  ),
                ),

                // ==========================================
                // 2. 🔹 THE STATIC LIGHT REFLECTION (THE BOWTIE FIX)
                // ==========================================
                RepaintBoundary(
                  child: IgnorePointer(
                    child: ClipOval(
                      // 🔹 Prevents the blur from leaking outside the record
                      child: ImageFiltered(
                        // 🔹 The Magic Fix: Blurs the harsh GPU polygons into a smooth photographic reflection
                        imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: Container(
                          width: 220,
                          height: 220,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: SweepGradient(
                              transform: const GradientRotation(-math.pi / 4),
                              colors: [
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(
                                  0.25,
                                ), // Top-left flare (boosted slightly to survive the blur)
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(
                                  0.0,
                                ), // Stays pitch black across the sides
                                Colors.white.withOpacity(
                                  0.12,
                                ), // Bottom-right flare
                                Colors.white.withOpacity(0.0),
                                Colors.white.withOpacity(0.0),
                              ],
                              // 🔹 Pinched the stops tightly to create the classic narrow "Bowtie" shape
                              stops: const [
                                0.0,
                                0.12, // Peak of top-left bowtie
                                0.25, // Fades completely to dark
                                0.50, // Holds dark
                                0.62, // Peak of bottom-right bowtie
                                0.75, // Fades completely to dark
                                1.0,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ==========================================
                // 3. 🔹 THE SPINNING ALBUM ART (Sandwiched on top of glare)
                // ==========================================
                AnimatedBuilder(
                  animation: _controller,
                  builder: (_, child) => Transform.rotate(
                    angle: _controller.value * 2 * math.pi,
                    child: child,
                  ),
                  child: ClipOval(
                    child: SizedBox(
                      width: 90,
                      height: 90,
                      child: widget.albumArtUrl.isNotEmpty
                          ? Image.network(widget.albumArtUrl, fit: BoxFit.cover)
                          : Container(color: Colors.redAccent),
                    ),
                  ),
                ),

                // ==========================================
                // 4. THE CENTER PIN HOLE
                // ==========================================
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

                // ==========================================
                // 5. THE PLAY / PAUSE OVERLAY
                // ==========================================
                GestureDetector(
                  onTap: _togglePlay,
                  child: Container(
                    width: 220,
                    height: 220,
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
                              size: 100,
                            ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Text(
              widget.songTitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.artist,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),

            const Divider(indent: 25, endIndent: 25),
            //const SizedBox(height: 25),
            if (widget.platformLinks.isNotEmpty) ...[
              // const Text(
              //   "Listen to full song on:",
              //   style: TextStyle(
              //     color: Color(0xFFF2F2F2),
              //     fontSize: 12,
              //     fontWeight: FontWeight.bold,
              //   ),
              // ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  // 1. Generate the buttons and strip out the nulls
                  final validButtons = widget.platformLinks.entries
                      .map(
                        (entry) => _buildPlatformButton(entry.key, entry.value),
                      )
                      .whereType<
                        Widget
                      >() // 🔹 Drops all the nulls from the list!
                      .toList();

                  // 2. If no valid streaming services exist, show the fallback
                  if (validButtons.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        "No streaming service found",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    );
                  }

                  // 3. Otherwise, render the wrap!
                  return Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: validButtons,
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget? _buildPlatformButton(String platformName, String url) {
    String svgPath;
    switch (platformName.toLowerCase()) {
      case 'spotify':
        svgPath = 'assets/icons/spotify-icon.svg';
        break;
      case 'apple music':
      case 'apple':
        svgPath = 'assets/icons/apple-music-icon.svg';
        break;
      case 'youtube':
        svgPath = 'assets/icons/youtube-music-icon.svg';
        break;
      default:
        return null;
    }

    return GestureDetector(
      onTap: () => _launchStreamingApp(url),
      // 🔹 1. SizedBox guarantees every item takes up the exact same horizontal space in the Wrap
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // 🔹 2. The Squircle wrapping ONLY the icon
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(
                  16,
                ), // Gives it the rounded square look
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Center(
                child: SvgPicture.asset(
                  svgPath,
                  width:
                      26, // Scaled slightly to fit the new 56x56 box perfectly
                  height: 26,
                ),
              ),
            ),

            const SizedBox(height: 8), // Gap between the icon box and the text
            // 🔹 3. The Text sitting underneath
            Text(
              platformName.toUpperCase().replaceAll(' ', '\n'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 10,
                height: 1.1,
                letterSpacing: 0.5,
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
  final AudioPlayer _audioPlayer = AudioPlayer();
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
    } catch (e) {}
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
        physics:
            const NeverScrollableScrollPhysics(), // Allows main card to scroll
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
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
            GestureDetector(
              onTap: _togglePlay,
              child: Icon(
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                color: const Color(0xFFD35400),
                size: 80,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 🔹 4. THE DATA MODEL
// ============================================================================
class Moment {
  final String id;
  final String authorName;
  final String avatarUrl;
  final DateTime timestamp;
  final MomentMedia media;
  final String caption;
  final Map<SpotReactions, int> reactionCounts;
  final int commentCount;

  SpotReactions? userReaction;

  Moment({
    required this.id,
    required this.authorName,
    required this.avatarUrl,
    required this.timestamp,
    required Map<String, dynamic> payload,
    required this.reactionCounts,
    this.caption = "",
    this.commentCount = 0,
    this.userReaction,
  }) : media = MomentMedia.fromJson(payload);

  int get totalReactions =>
      reactionCounts.values.fold(0, (sum, val) => sum + val);

  List<SpotReactions> get top3Reactions {
    var sortedEntries = reactionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.take(3).map((e) => e.key).toList();
  }
}

// ============================================================================
// 🔹 5. THE SPOT DISPLAY SCREEN (MAIN CAROUSEL)
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

  // --- EXPANDED DUMMY DATA ---
  final List<Moment> _moments = [
    Moment(
      id: '1',
      authorName: 'User_test42',
      avatarUrl: 'https://i.pravatar.cc/150?u=david',
      timestamp: DateTime(2025, 2, 12),
      reactionCounts: {
        SpotReactions.wholesome: 100000,
        SpotReactions.funny: 40000,
        SpotReactions.wow: 5000,
      },
      caption:
          "This view is insane at sunset! You should visit the roof, it has a great view. came here at 4 PM and barely had any crowd with all the view for myself :)",
      commentCount: 56,
      payload: {
        'type': 'photo',
        'url':
            'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=800&q=80',
      },
    ),
    Moment(
      id: '2',
      authorName: 'Maya_T',
      avatarUrl: 'https://i.pravatar.cc/150?u=maya',
      timestamp: DateTime(2025, 3, 22),
      reactionCounts: {SpotReactions.insightful: 500},
      caption: "Recorded the rain hitting the tin roof today.",
      commentCount: 4,
      payload: {
        'type': 'audio',
        'title': 'Morning Rain Sounds',
        'duration': '1:45',
        'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      },
    ),
    Moment(
      id: '3',
      authorName: 'Alex_M',
      avatarUrl: 'https://i.pravatar.cc/150?u=alex',
      timestamp: DateTime(2025, 6, 15),
      reactionCounts: {SpotReactions.wow: 200, SpotReactions.support: 50},
      caption: "Current mood.",
      commentCount: 12,
      payload: {
        // 🔹 ADDED ODESLI LINKS BACK IN!
        'type': 'music', 'song_title': 'Midnight City', 'artist': 'M83',
        'album_art':
            'https://images.unsplash.com/photo-1619983081563-430f63602796?w=800&q=80',
        'preview_url':
            'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        'platform_links': {
          'Spotify': 'https://open.spotify.com/track/123',
          'Apple Music': 'https://music.apple.com/123',
        },
      },
    ),
    Moment(
      id: '4',
      authorName: 'Sarah_J',
      avatarUrl: 'https://i.pravatar.cc/150?u=sarah',
      timestamp: DateTime(2025, 10, 15),
      reactionCounts: {
        SpotReactions.funny: 145000,
        SpotReactions.wholesome: 2300,
        SpotReactions.wow: 150,
      },
      commentCount: 400,
      payload: {
        'type': 'poll',
        'question': 'Best time to visit this spot?',
        'options': ['Sunrise', 'Sunset', 'Midnight'],
      },
    ),
    Moment(
      id: '5',
      authorName: 'Sarah_J',
      avatarUrl: 'https://i.pravatar.cc/150?u=sarah',
      timestamp: DateTime(2024, 10, 15),
      reactionCounts: {
        SpotReactions.funny: 145,
        SpotReactions.wholesome: 2300,
        SpotReactions.wow: 150,
      },
      commentCount: 8, // Intentionally blank caption for Text moments
      payload: {
        'type': 'text',
        'text':
            'This is the most incredible hidden spot in the city. I love coming here to read and grab a coffee!',
      },
    ),
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = _moments.length - 1;
    _stageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.85,
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

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  String _getMonthName(int month) => [
    'Jan',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];

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
    // 🔹 1. PREVENT 296px VERTICAL OVERFLOW: Dynamically calculate exact PageView height
    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = screenWidth * 0.85;
    final double safePageViewHeight =
        cardWidth +
        130; // 1:1 Aspect + Date Text + Margins (was 140 originally)

    return Scaffold(
      backgroundColor: const Color(0xFFF3F2EB),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 16),
              SizedBox(
                height:
                    safePageViewHeight, // Safely handles wide phones and tablets!
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
              _buildTimeScrubber(),
              const SizedBox(height: 35),
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
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.black87,
                    size: 28,
                  ),
                ),
              ),
              const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.public, color: Colors.black87, size: 18),
                  SizedBox(width: 6),
                  Text(
                    "Public",
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.only(bottom: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.black54, width: 2),
                    ),
                  ),
                  child: Text(
                    widget.spotTitle,
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: -0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              const Icon(
                Icons.bookmark_border,
                color: Colors.black87,
                size: 40,
              ),
            ],
          ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _formatDate(moment.timestamp),
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _openMomentFullScreen(moment),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: Hero(
                tag: 'moment_card_${moment.id}',
                child: Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.5),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AspectRatio(
                          aspectRatio: 1.0,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [moment.media.buildPreview(context)],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 18,
                              backgroundImage: NetworkImage(moment.avatarUrl),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "@${moment.authorName}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: Colors.black87,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            OverlappingReactionStack(
                              reactions: moment.top3Reactions,
                              totalReactions: moment.totalReactions,
                              scale: 1,
                              counterTextColor: Colors.black87,
                              outlineColor: Colors.white,
                            ), // Slightly shrunk scale
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeScrubber() {
    return SizedBox(
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
                      int newIndex = (_timelineController.offset / _nodeWidth)
                          .round()
                          .clamp(0, _moments.length - 1);
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
                    Moment m = _moments[index];
                    bool isYear = m.timestamp.month == 1 || index == 0;
                    bool isLast = index == _moments.length - 1;
                    String topText = isYear ? m.timestamp.year.toString() : "";
                    if (isLast) topText = "Now";
                    String bottomText = !isYear && !isLast
                        ? _getMonthName(m.timestamp.month)
                        : "";
                    return SizedBox(
                      width: _nodeWidth,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            height: 20,
                            child: Text(
                              topText,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 40,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 2,
                                  color: Colors.grey[500],
                                  margin: EdgeInsets.only(
                                    left: index == 0 ? _nodeWidth / 2 : 0,
                                    right: isLast ? _nodeWidth / 2 : 0,
                                  ),
                                ),
                                Container(
                                  width: isYear || isLast ? 20.0 : 12.0,
                                  height: isYear || isLast ? 20.0 : 12.0,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[600],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 20,
                            child: Text(
                              bottomText,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 12,
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
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: Colors.blueAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCuratedSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            "Spot Soundtrack",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 140,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 4,
            itemBuilder: (context, index) {
              return Container(
                width: 140,
                margin: const EdgeInsets.only(right: 16),
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
                      fontSize: 14,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 🔹 THE FULL SCREEN VIEW
// ============================================================================
class MomentFullScreenView extends StatefulWidget {
  final Moment moment;
  const MomentFullScreenView({super.key, required this.moment});
  @override
  State<MomentFullScreenView> createState() => _MomentFullScreenViewState();
}

class _MomentFullScreenViewState extends State<MomentFullScreenView> {
  // 🔹 The Centralized Data Updater
  // This safely handles swapping, adding, and removing reactions
  void _handleReactionSelect(
    SpotReactions tappedReaction,
    VoidCallback? updateListSheet,
  ) {
    setState(() {
      SpotReactions? oldReaction = widget.moment.userReaction;

      if (oldReaction == tappedReaction) {
        // SCENARIO 1: Tapping the already selected reaction (Remove it)
        // 🔹 FIX: We use tappedReaction here since we know it equals oldReaction and is non-null!
        widget.moment.reactionCounts[tappedReaction] =
            (widget.moment.reactionCounts[tappedReaction] ?? 1) - 1;

        if (widget.moment.reactionCounts[tappedReaction] == 0) {
          widget.moment.reactionCounts.remove(tappedReaction);
        }

        widget.moment.userReaction = null;
      } else {
        // SCENARIO 2: Tapping a new reaction (Swap or Add)
        if (oldReaction != null) {
          // Remove the old one first
          // 🔹 FIX: Added the '!' operator to tell Dart it is definitely not null
          widget.moment.reactionCounts[oldReaction!] =
              (widget.moment.reactionCounts[oldReaction] ?? 1) - 1;

          if (widget.moment.reactionCounts[oldReaction] == 0) {
            widget.moment.reactionCounts.remove(oldReaction);
          }
        }

        // Add the new one
        widget.moment.userReaction = tappedReaction;
        widget.moment.reactionCounts[tappedReaction] =
            (widget.moment.reactionCounts[tappedReaction] ?? 0) + 1;
      }
    });

    // If the list bottom sheet is open, this forces it to visually update!
    updateListSheet?.call();
  }

  void _showReactionsList() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (BuildContext sheetContext) {
        // 🔹 StatefulBuilder lets us update the bottom sheet instantly without closing it
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            // Sort the list fresh on every rebuild
            var sortedEntries = widget.moment.reactionCounts.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value));

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16.0,
                  horizontal: 16.0,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🔹 THE DRAG HANDLE
                    Container(
                      width: 40,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2.5),
                      ),
                    ),
                    Text(
                      "${formatNumberWithCommas(widget.moment.totalReactions)} Reactions",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),

                    Expanded(
                      child: ListView.builder(
                        // 🔹 Add 1 to the count to make room for our special top row
                        itemCount: sortedEntries.length + 1,
                        itemBuilder: (context, index) {
                          // ==========================================
                          // THE SPECIAL TOP ROW (Index 0)
                          // ==========================================
                          if (index == 0) {
                            if (widget.moment.userReaction != null) {
                              // STATE 1: User HAS reacted -> Show Green "Remove" Pill
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    // 🔹 Opens selector AND passes the setState function so the list updates live!
                                    _showReactionSelector(
                                      updateListSheet: () =>
                                          setSheetState(() {}),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                      bottom: 16,
                                      top: 8,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.green.shade300,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          widget.moment.userReaction!.assetPath,
                                          width: 28,
                                          height: 28,
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          "Tap to change",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            color: Colors.green,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            } else {
                              // STATE 2: User has NOT reacted -> Show "Add Reaction" Button
                              return Align(
                                alignment: Alignment.centerLeft,
                                child: GestureDetector(
                                  onTap: () {
                                    HapticFeedback.lightImpact();
                                    // 🔹 Opens selector AND passes the setState function
                                    _showReactionSelector(
                                      updateListSheet: () =>
                                          setSheetState(() {}),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(
                                      bottom: 24,
                                      top: 8,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: Colors.grey.shade300,
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 28,
                                          height: 28,
                                          decoration: const BoxDecoration(
                                            color: Colors.white,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.add_reaction_outlined,
                                            color: Colors.black54,
                                            size: 30,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        const Text(
                                          "Add a reaction",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }
                          }

                          // ==========================================
                          // THE STANDARD LIST (Index 1+)
                          // ==========================================
                          // We subtract 1 from the index because the 0th item is our special row
                          final entry = sortedEntries[index - 1];
                          return ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 8,
                            ),
                            leading: Image.asset(
                              entry.key.assetPath,
                              width: 32,
                              height: 32,
                            ),
                            title: Text(
                              entry.key.name.toUpperCase(),
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            trailing: Text(
                              formatNumberWithCommas(entry.value),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black54,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // 🔹 Optionally accepts a callback so the list sheet can rebuild if it's open behind this one
  void _showReactionSelector({VoidCallback? updateListSheet}) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (context) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // 🔹 Passing the Enums directly
                _buildAnimatedEmojiBtn(SpotReactions.funny, updateListSheet),
                _buildAnimatedEmojiBtn(SpotReactions.wow, updateListSheet),
                _buildAnimatedEmojiBtn(
                  SpotReactions.wholesome,
                  updateListSheet,
                ),
                _buildAnimatedEmojiBtn(
                  SpotReactions.insightful,
                  updateListSheet,
                ),
                _buildAnimatedEmojiBtn(SpotReactions.sad, updateListSheet),
                _buildAnimatedEmojiBtn(SpotReactions.meh, updateListSheet),
                _buildAnimatedEmojiBtn(SpotReactions.support, updateListSheet),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAnimatedEmojiBtn(
    SpotReactions reaction,
    VoidCallback? updateListSheet,
  ) {
    bool isSelected = widget.moment.userReaction == reaction;

    return GestureDetector(
      onTap: () {
        HapticFeedback.heavyImpact();
        Navigator.pop(context); // Close the selector
        _handleReactionSelect(
          reaction,
          updateListSheet,
        ); // Trigger the swap logic
      },
      child: Container(
        padding: const EdgeInsets.all(
          5,
        ), // Gives the emoji room inside the grey circle
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          // 🔹 Shows the Grey Selection Circle
          color: isSelected
              // ? Colors.grey.withValues(alpha: 0.4)
              ? Colors.green.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
        child: Image.asset(
          reaction.animatedAssetPath,
          width: 35,
          height: 35,
          errorBuilder: (context, error, stackTrace) =>
              const Icon(Icons.emoji_emotions, size: 40, color: Colors.amber),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // const Color buttonsBackgroundColor = Color(0xFF636A73);
    const Color buttonsBackgroundColor = Color(0xFF545454);
    // const Color buttonsBackgroundColor = Color(0xFF3D3D3D);

    return Scaffold(
      backgroundColor: Colors.black.withValues(alpha: 0.85),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Fixed Top Header
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: buttonsBackgroundColor,
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
                    "${widget.moment.timestamp.day.toString().padLeft(2, '0')}/${widget.moment.timestamp.month.toString().padLeft(2, '0')}/${widget.moment.timestamp.year}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // 2. 🔹 FIXED: The Constant Size Scroll Container
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Hero(
                  tag: 'moment_card_${widget.moment.id}',
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      // The container acts as the physical window, the content scrolls fluidly inside
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          // All media blocks are forced to a perfect 3:4 vertical portrait
                          final double mediaHeight =
                              constraints.maxWidth * (4 / 3);

                          return SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // A. The Media Block
                                    SizedBox(
                                      height: mediaHeight,
                                      child: widget.moment.media.buildExpanded(
                                        context,
                                      ),
                                    ),

                                    // B. The White Context Area
                                    Container(
                                      color: Colors.white,
                                      padding: const EdgeInsets.fromLTRB(
                                        20,
                                        7,
                                        20,
                                        20,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              const SizedBox(
                                                width: 50,
                                              ), // Leaves room for avatar
                                              Expanded(
                                                child: Text(
                                                  "@${widget.moment.authorName}",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6,
                                                    ),
                                                decoration: BoxDecoration(
                                                  border: Border.all(
                                                    color: Colors.grey.shade300,
                                                  ),
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .photo_library_outlined,
                                                      size: 16,
                                                      color: Colors.black54,
                                                    ),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      "Tel Aviv Moments",
                                                      style: TextStyle(
                                                        color: Colors.blue[800],
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),

                                          const SizedBox(height: 10),

                                          // Conditionally render the caption only if it exists
                                          if (widget
                                              .moment
                                              .caption
                                              .isNotEmpty) ...[
                                            const Divider(height: 1),
                                            const SizedBox(height: 12),
                                            Text(
                                              widget.moment.caption,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                color: Colors.black87,
                                                height: 1.4,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // C. Overlapping Avatar (Seamed dynamically!)
                                Positioned(
                                  left: 0,
                                  top: mediaHeight - 30,
                                  child: Container(
                                    padding: const EdgeInsets.all(3),
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: CircleAvatar(
                                      radius: 30,
                                      backgroundImage: NetworkImage(
                                        widget.moment.avatarUrl,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // 3. 🔹 FIXED 20px HORIZONTAL OVERFLOW: Smaller paddings on bottom bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: buttonsBackgroundColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.moment.commentCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(), // Safely takes remaining width
                  // The Split Reaction Pill (No outlines here!)
                  Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: buttonsBackgroundColor,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        InkWell(
                          onTap: _showReactionsList,
                          borderRadius: const BorderRadius.horizontal(
                            left: Radius.circular(22),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 10),
                            child: OverlappingReactionStack(
                              reactions: widget.moment.top3Reactions,
                              totalReactions: widget.moment.totalReactions,
                              scale:
                                  0.9, // Scaled down to guarantee no overflow
                              outlineColor: buttonsBackgroundColor,
                              counterTextColor: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          width: 2,
                          height: 30,
                          color: Color(0xFF404040),
                        ),
                        InkWell(
                          // 🔹 Opens the selector directly. No need for updateListSheet here since list is closed.
                          onTap: () => _showReactionSelector(),
                          borderRadius: const BorderRadius.horizontal(
                            right: Radius.circular(22),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.only(left: 10, right: 15),
                            // 🔹 THE DYNAMIC ICON: Shows selected image OR the default icon!
                            child: widget.moment.userReaction != null
                                ? Image.asset(
                                    widget.moment.userReaction!.assetPath,
                                    width: 22,
                                    height: 22,
                                  )
                                : const Icon(
                                    Icons.add_reaction_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  //const SizedBox(width: 8),
                  const Spacer(),

                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: buttonsBackgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.bookmark_border,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: buttonsBackgroundColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.share_outlined,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ],
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
