import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'dart:math' as math;
// import 'package:url_launcher/url_launcher.dart';
// import 'package:just_audio/just_audio.dart';
// import 'package:spots_app/utils/models.dart';
import 'package:spots_app/components/overlapping_reaction_stack.dart';
// import 'package:intl/intl.dart';
// import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui';
import 'package:spots_app/screens/moment_full_screen_view.dart';
import 'package:spots_app/utils/moment_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SpotDisplayScreen extends StatefulWidget {
  final String spotId;
  final String spotTitle;

  const SpotDisplayScreen({
    super.key,
    required this.spotId,
    required this.spotTitle,
  });
  @override
  State<SpotDisplayScreen> createState() => _SpotDisplayScreenState();
}

class _SpotDisplayScreenState extends State<SpotDisplayScreen> {
  late PageController _stageController;
  late ScrollController _timelineController;

  int _currentIndex = 0;
  bool _isDraggingTimeline = false;
  final double _nodeWidth = 80.0;

  late Future<List<Moment>> _momentsFuture;

  // // --- EXPANDED DUMMY DATA ---
  // final List<Moment> _moments = [
  //   Moment(
  //     id: '1',
  //     authorName: 'User_test42',
  //     avatarUrl: 'https://i.pravatar.cc/150?u=david',
  //     timestamp: DateTime(2025, 2, 12),
  //     reactionCounts: {
  //       SpotReactions.wholesome: 100000,
  //       SpotReactions.funny: 40000,
  //       SpotReactions.wow: 5000,
  //     },
  //     caption:
  //         "This view is insane at sunset! You should visit the roof, it has a great view. came here at 4 PM and barely had any crowd with all the view for myself :)",
  //     commentCount: 56,
  //     payload: {
  //       'type': 'photo',
  //       'url':
  //           'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=800&q=80',
  //     },
  //   ),
  //   Moment(
  //     id: '2',
  //     authorName: 'Maya_T',
  //     avatarUrl: 'https://i.pravatar.cc/150?u=maya',
  //     timestamp: DateTime(2025, 3, 22),
  //     reactionCounts: {SpotReactions.insightful: 500},
  //     caption: "Recorded the rain hitting the tin roof today.",
  //     commentCount: 4,
  //     payload: {
  //       'type': 'audio',
  //       'title': 'Morning Rain Sounds',
  //       'duration': '1:45',
  //       'url': 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  //     },
  //   ),
  //   Moment(
  //     id: '3',
  //     authorName: 'Alex_M',
  //     avatarUrl: 'https://i.pravatar.cc/150?u=alex',
  //     timestamp: DateTime(2025, 6, 15),
  //     reactionCounts: {SpotReactions.wow: 200, SpotReactions.support: 50},
  //     caption: "Current mood.",
  //     commentCount: 12,
  //     payload: {
  //       // 🔹 ADDED ODESLI LINKS BACK IN!
  //       'type': 'music', 'song_title': 'Midnight City', 'artist': 'M83',
  //       'album_art':
  //           'https://images.unsplash.com/photo-1619983081563-430f63602796?w=800&q=80',
  //       'preview_url':
  //           'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
  //       'platform_links': {
  //         'Spotify': 'https://open.spotify.com/track/123',
  //         'Apple Music': 'https://music.apple.com/123',
  //       },
  //     },
  //   ),
  //   Moment(
  //     id: '4',
  //     authorName: 'Sarah_J',
  //     avatarUrl: 'https://i.pravatar.cc/150?u=sarah',
  //     timestamp: DateTime(2025, 10, 15),
  //     reactionCounts: {
  //       SpotReactions.funny: 145000,
  //       SpotReactions.wholesome: 2300,
  //       SpotReactions.wow: 150,
  //     },
  //     commentCount: 400,
  //     payload: {
  //       'type': 'poll',
  //       'question': 'Best time to visit this spot?',
  //       'options': ['Sunrise', 'Sunset', 'Midnight'],
  //     },
  //   ),
  //   Moment(
  //     id: '5',
  //     authorName: 'Sarah_J',
  //     avatarUrl: 'https://i.pravatar.cc/150?u=sarah',
  //     timestamp: DateTime(2024, 10, 15),
  //     reactionCounts: {
  //       SpotReactions.funny: 145,
  //       SpotReactions.wholesome: 2300,
  //       SpotReactions.wow: 150,
  //     },
  //     commentCount: 8, // Intentionally blank caption for Text moments
  //     payload: {
  //       'type': 'text',
  //       'text':
  //           'This is the most incredible hidden spot in the city. I love coming here to read and grab a coffee!',
  //     },
  //   ),
  // ];

  @override
  void initState() {
    super.initState();
    // 🔹 Fetch the data when the screen loads!
    _momentsFuture = _fetchSpotMoments();

    _stageController = PageController(viewportFraction: 0.85);
    _timelineController = ScrollController();
  }

  Future<List<Moment>> _fetchSpotMoments() async {
    try {
      // 🔹 Assumes a 'moments' table joined with a 'profiles' table for user info
      final response = await Supabase.instance.client
          .from('moments')
          .select('*, users!moments_user_id_fkey(username, profile_picture)')
          .eq('spot_id', widget.spotId)
          .order(
            'created_at',
            ascending: true,
          ); // Chronological order for the timeline

      List<Moment> fetchedMoments = (response as List)
          .map((data) => Moment.fromMap(data))
          .toList();

      // Initialize the controllers to the most recent moment (the end of the list)
      if (fetchedMoments.isNotEmpty) {
        _currentIndex = fetchedMoments.length - 1;
        _stageController = PageController(
          initialPage: _currentIndex,
          viewportFraction: 0.85,
        );
        _timelineController = ScrollController(
          initialScrollOffset: _currentIndex * _nodeWidth,
        );
      }

      return fetchedMoments;
    } catch (e) {
      debugPrint("Error fetching moments: $e");
      return [];
    }
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
    return Scaffold(
      backgroundColor: const Color(0xFFF3F2EB),
      body: SafeArea(
        child: FutureBuilder<List<Moment>>(
          future: _momentsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            }

            final moments = snapshot.data ?? [];

            if (moments.isEmpty) {
              return Column(
                children: [
                  _buildHeader(),
                  const Expanded(
                    child: Center(
                      child: Text(
                        "No moments here yet.\nBe the first to create one!",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18, color: Colors.black54),
                      ),
                    ),
                  ),
                ],
              );
            }

            final double screenWidth = MediaQuery.of(context).size.width;
            final double cardWidth = screenWidth * 0.85;
            final double safePageViewHeight = cardWidth + 130;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  _buildHeader(),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: safePageViewHeight,
                    child: PageView.builder(
                      controller: _stageController,
                      physics: const BouncingScrollPhysics(),
                      onPageChanged: _onStagePageChanged,
                      itemCount: moments.length,
                      itemBuilder: (context, index) {
                        // 🔹 Pass the fetched moments to your existing UI builder!
                        return _buildPolaroidCard(moments, index);
                      },
                    ),
                  ),
                  _buildTimeScrubber(
                    moments,
                  ), // 🔹 Pass the fetched moments here too
                  const SizedBox(height: 35),
                  _buildCuratedSections(),
                  const SizedBox(height: 60),
                ],
              ),
            );
          },
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

  Widget _buildPolaroidCard(List<Moment> moments, int index) {
    final Moment moment = moments[index];

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
        ],
      ),
    );
  }

  Widget _buildTimeScrubber(List<Moment> moments) {
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
                      // 🔹 FIX: Replaced _moments with moments
                      int newIndex = (_timelineController.offset / _nodeWidth)
                          .round()
                          .clamp(0, moments.length - 1);
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
                  itemCount:
                      moments.length, // 🔹 FIX: Replaced _moments with moments
                  itemBuilder: (context, index) {
                    Moment m =
                        moments[index]; // 🔹 FIX: Replaced _moments with moments
                    bool isYear = m.timestamp.month == 1 || index == 0;
                    bool isLast =
                        index ==
                        moments.length -
                            1; // 🔹 FIX: Replaced _moments with moments
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
