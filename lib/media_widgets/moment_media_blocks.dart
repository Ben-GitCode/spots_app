import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:ui';
import 'package:url_launcher/url_launcher.dart';
import 'package:just_audio/just_audio.dart';
import 'package:simple_icons/simple_icons.dart';
import 'package:video_player/video_player.dart';
import 'package:text_scroll/text_scroll.dart';

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
      return TextMedia(json?['text']);
    }
    if (type == 'image') {
      return ImageMedia(json!['url']);
    }
    if (type == 'poll') {
      return PollMedia(
        json?['question'] ?? 'Poll',
        List<String>.from(json?['options'] ?? []),
      );
    }
    if (type == 'audio') {
      return AudioMedia(
        json!['title'] ?? 'Voice Note',
        json['duration'] ?? '0:00',
        json['url'] ?? '',
      );
    }
    if (type == 'video') {
      return VideoMedia(
        videoUrl: json!['url'] ?? '',
        thumbnailUrl:
            json['thumbnail_url'], // Safely reads the thumbnail if it exists
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

class ImageMedia implements MomentMedia {
  final String url;
  ImageMedia(this.url);
  @override
  Widget buildPreview(BuildContext context) =>
      Image.network(url, fit: BoxFit.cover);
  @override
  Widget buildExpanded(BuildContext context) =>
      // 🔹 Enforces 3:4 and crops any excess width/height perfectly
      AspectRatio(
        aspectRatio: 3 / 4,
        child: Image.network(url, fit: BoxFit.cover, width: double.infinity),
      );
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

IconData _getPlatformIcon(String platformName) {
  switch (platformName) {
    case 'Spotify':
      return SimpleIcons.spotify;
    case 'Apple Music':
      return SimpleIcons.applemusic; // The actual Apple Music logo!
    case 'YouTube Music':
      return SimpleIcons.youtubemusic; // Dedicated YT Music logo
    case 'YouTube':
      return SimpleIcons.youtube;
    case 'SoundCloud':
      return SimpleIcons.soundcloud;
    case 'Amazon Music':
      return SimpleIcons.amazonmusic;
    case 'Pandora':
      return SimpleIcons.pandora;
    case 'Audiomack':
      return SimpleIcons.audiomack;
    case 'Tidal':
      return SimpleIcons.tidal;
    // case 'Deezer':
    //   return SimpleIcons.graphic_eq_rounded;
    default:
      // A safe fallback just in case Odesli ever adds a platform you haven't mapped yet
      return Icons.music_note_rounded;
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

class VideoMedia implements MomentMedia {
  final String videoUrl;
  final String? thumbnailUrl;

  VideoMedia({required this.videoUrl, this.thumbnailUrl});

  @override
  Widget buildPreview(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Show the thumbnail if we have it, otherwise a black box
        if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty)
          Image.network(thumbnailUrl!, fit: BoxFit.cover)
        else
          Container(color: const Color(0xFF141418)),

        // 2. Overlay a play button to indicate it's a video
        Container(
          color: Colors.black.withOpacity(0.2),
          child: const Center(
            child: Icon(Icons.play_circle_fill, color: Colors.white, size: 48),
          ),
        ),
      ],
    );
  }

  @override
  Widget buildExpanded(BuildContext context) {
    return VideoPlayerWidget(videoUrl: videoUrl);
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  const VideoPlayerWidget({super.key, required this.videoUrl});

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _isInitialized = true);
          _controller.setLooping(true);
          // Waiting for the user's tap to play!
        }
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _controller.value.isPlaying ? _controller.pause() : _controller.play();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const AspectRatio(
        aspectRatio: 3 / 4,
        child: Center(child: CircularProgressIndicator(color: Colors.white54)),
      );
    }

    // 🔹 1. Define your strict window
    const double targetRatio = 3 / 4;

    // 🔹 2. Get the true, rotated aspect ratio of the video
    final double videoRatio = _controller.value.aspectRatio;

    // 🔹 3. Mathematically calculate the exact zoom needed to push black bars off the screen
    final double scale = videoRatio < targetRatio
        ? targetRatio / videoRatio
        : videoRatio / targetRatio;

    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        color: Colors.black, // Cinematic backdrop
        width: double.infinity,
        child: AspectRatio(
          aspectRatio: targetRatio, // Locks the outer box to 3:4
          child: ClipRect(
            // Slices off whatever spills out!
            child: Stack(
              alignment: Alignment.center,
              fit: StackFit.expand,
              children: [
                // ==========================================
                // 🔹 THE MATHEMATICAL CROP
                // ==========================================
                Center(
                  child: Transform.scale(
                    scale: scale,
                    child: AspectRatio(
                      aspectRatio: videoRatio,
                      child: VideoPlayer(_controller),
                    ),
                  ),
                ),

                // ==========================================
                // 🔹 PLAY BUTTON OVERLAY
                // ==========================================
                if (!_controller.value.isPlaying)
                  Container(
                    color: Colors.black.withOpacity(0.15),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
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
          _audioPlayer.pause();
          _audioPlayer.seek(Duration.zero);

          setState(() {
            _isPlaying = false;
            _controller.stop();
          });
        }
      });
    } catch (e) {
      debugPrint("Audio init error: $e");
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
            // Text(
            //   widget.songTitle,
            //   textAlign: TextAlign.center,
            //   style: const TextStyle(
            //     fontSize: 24,
            //     fontWeight: FontWeight.bold,
            //     color: Colors.white,
            //   ),
            // ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: TextScroll(
                widget.songTitle,
                mode: TextScrollMode.endless, // Infinite car radio loop
                velocity: const Velocity(pixelsPerSecond: Offset(40, 0)),
                delayBefore: const Duration(seconds: 2),
                pauseBetween: const Duration(seconds: 2),

                intervalSpaces: 10,

                // ==========================================
                // 🔹 THE PREMIUM TOUCH: EDGE FADES
                // ==========================================
                fadedBorder: true,
                // Creates a smooth gradient fade on the outer 8% of the container
                // so the text gracefully disappears instead of harshly clipping!
                fadedBorderWidth: 0.08,

                textAlign:
                    TextAlign.center, // Keeps short titles perfectly centered
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              widget.artist,
              style: const TextStyle(fontSize: 16, color: Colors.white70),
            ),

            const Divider(indent: 25, endIndent: 25),
            //const SizedBox(height: 25),
            Builder(
              builder: (context) {
                // 1. Clone the map so we can safely edit it
                Map<String, dynamic> cleanedLinks = Map.from(
                  widget.platformLinks,
                );

                // 2. 🔹 THE REDUNDANCY FILTER
                // If YT Music exists, scrub standard YouTube from the list
                if (cleanedLinks.containsKey('YouTube Music') &&
                    cleanedLinks.containsKey('YouTube')) {
                  cleanedLinks.remove('YouTube');
                }

                // 3. 🔹 THE SORTING ALGORITHM
                // This mathematically forces the "Big 3" to the front of the line
                final desiredOrder = [
                  'Spotify',
                  'Apple Music',
                  'YouTube Music',
                  'YouTube',
                  'SoundCloud',
                  'Amazon Music',
                  'Pandora',
                  'Audiomack',
                  'Tidal',
                  'Deezer',
                ];

                final sortedKeys = cleanedLinks.keys.toList()
                  ..sort((a, b) {
                    int indexA = desiredOrder.indexOf(a);
                    int indexB = desiredOrder.indexOf(b);
                    if (indexA == -1) indexA = 999; // Unknowns go to the back
                    if (indexB == -1) indexB = 999;
                    return indexA.compareTo(indexB);
                  });

                // 4. Generate the widgets using our sorted list
                final validButtons = sortedKeys
                    .map((key) => _buildPlatformButton(key, cleanedLinks[key]))
                    .whereType<Widget>()
                    .toList();

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

                // 5. 🔹 THE HORIZONTAL SCROLL
                return Center(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    // If there are 2 items, Row centers them. If there are 6, it scrolls!
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: validButtons
                          .map(
                            (btn) => Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8.0,
                              ),
                              child: btn,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildPlatformButton(String platformName, String url) {
    return GestureDetector(
      onTap: () => _launchStreamingApp(url),
      child: SizedBox(
        width: 64, // Slightly widened to fit long names
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withOpacity(0.15)),
              ),
              child: Center(
                // 🔹 Feeds the name into your new Simple Icons helper!
                child: Icon(
                  _getPlatformIcon(platformName),
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              platformName.toUpperCase().replaceAll(' ', '\n'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.bold,
                fontSize: 9, // Dropped to 9 to fit "YOUTUBE MUSIC" nicely
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
          _audioPlayer.pause();
          _audioPlayer.seek(Duration.zero);

          setState(() {
            _isPlaying = false;
            _controller.stop();
          });
        }
      });
    } catch (e) {
      debugPrint("Audio init error: $e");
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
