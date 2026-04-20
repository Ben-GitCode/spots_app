import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_svg/flutter_svg.dart';

// ============================================================================
// 🔹 2. THE POLYMORPHIC MEDIA ARCHITECTURE
// ============================================================================
abstract class MomentMedia {
  Widget buildPreview(BuildContext context);
  Widget buildExpanded(BuildContext context);

  // 🔹 NEW: Takes the nullable JSON payload AND the SQL caption
  factory MomentMedia.fromData(Map<String, dynamic>? json, String caption) {
    // If json is null, it's guaranteed to be a text post
    final type = json?['type'] ?? 'text';

    if (type == 'text') {
      // 🔹 It now naturally reads the SQL caption directly! No fake JSON needed.
      return TextMedia(caption);
    }
    if (type == 'photo') {
      return PhotoMedia(json!['url']);
    }
    if (type == 'poll') {
      return PollMedia(
        json!['question'] ?? 'Poll',
        List<String>.from(json['options'] ?? []),
      );
    }
    if (type == 'audio') {
      return AudioMedia(
        json!['title'] ?? 'Voice Note',
        json['duration'] ?? '0:00',
        json['url'] ?? '',
      );
    }
    if (type == 'music') {
      return MusicMedia(
        json!['song_title'] ?? 'Unknown Song',
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
                IgnorePointer(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: ClipOval(
                      // 🔹 Guarantees the blur is cut into a perfect circle
                      child: ImageFiltered(
                        // 🔹 This blur engine is bulletproof on Android emulators
                        imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                        child: CustomPaint(
                          size: const Size(220, 220),
                          painter: VinylGlarePainter(),
                        ),
                      ),
                    ),
                  ),
                ),

                // RepaintBoundary(
                //   child: IgnorePointer(
                //     child: ClipOval(
                //       // 🔹 Prevents the blur from leaking outside the record
                //       child: ImageFiltered(
                //         // 🔹 The Magic Fix: Blurs the harsh GPU polygons into a smooth photographic reflection
                //         imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                //         child: Container(
                //           width: 220,
                //           height: 220,
                //           decoration: BoxDecoration(
                //             shape: BoxShape.circle,
                //             gradient: SweepGradient(
                //               transform: const GradientRotation(-math.pi / 4),
                //               colors: [
                //                 Colors.white.withOpacity(0.0),
                //                 Colors.white.withOpacity(
                //                   0.25,
                //                 ), // Top-left flare (boosted slightly to survive the blur)
                //                 Colors.white.withOpacity(0.0),
                //                 Colors.white.withOpacity(
                //                   0.0,
                //                 ), // Stays pitch black across the sides
                //                 Colors.white.withOpacity(
                //                   0.12,
                //                 ), // Bottom-right flare
                //                 Colors.white.withOpacity(0.0),
                //                 Colors.white.withOpacity(0.0),
                //               ],
                //               // 🔹 Pinched the stops tightly to create the classic narrow "Bowtie" shape
                //               stops: const [
                //                 0.0,
                //                 0.12, // Peak of top-left bowtie
                //                 0.25, // Fades completely to dark
                //                 0.50, // Holds dark
                //                 0.62, // Peak of bottom-right bowtie
                //                 0.75, // Fades completely to dark
                //                 1.0,
                //               ],
                //             ),
                //           ),
                //         ),
                //       ),
                //     ),
                //   ),
                // ),

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

class VinylGlarePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Inflate slightly so the light reaches the edge before blurring
    final rect = Rect.fromLTWH(0, 0, size.width, size.height).inflate(10);

    // 1. Raw top-left glare (No mask filter!)
    final Paint topFlarePaint = Paint()
      ..color = Colors.white.withOpacity(0.20)
      ..style = PaintingStyle.fill;

    // 2. Raw bottom-right glare (No mask filter!)
    final Paint bottomFlarePaint = Paint()
      ..color = Colors.white.withOpacity(0.10)
      ..style = PaintingStyle.fill;

    const double sweepAngle = math.pi / 4;
    const double topStartAngle = (-3 * math.pi / 4) - (sweepAngle / 2);
    const double bottomStartAngle = (math.pi / 4) - (sweepAngle / 2);

    canvas.drawArc(rect, topStartAngle, sweepAngle, true, topFlarePaint);
    canvas.drawArc(rect, bottomStartAngle, sweepAngle, true, bottomFlarePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
