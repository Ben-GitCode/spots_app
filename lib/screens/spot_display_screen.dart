import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- DUMMY DATA MODELS ---
enum MediaType { text, photo, audio, poll }

class Moment {
  final String id;
  final String authorName;
  final String avatarUrl;
  final DateTime timestamp;
  final MediaType type;
  final String content;
  final String emotionEmoji;

  Moment({
    required this.id,
    required this.authorName,
    required this.avatarUrl,
    required this.timestamp,
    required this.type,
    required this.content,
    required this.emotionEmoji,
  });
}

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
  bool _isDraggingTimeline = false; // 🔹 Prevents animation conflicts
  final double _nodeWidth =
      80.0; // 🔹 The physical width of each timeline "tick"

  // Dummy Data representing the "History" of this Spot
  // Ordered from oldest to newest to fit a left-to-right timeline
  final List<Moment> _moments = [
    Moment(
      id: '1',
      authorName: 'David L.',
      avatarUrl: 'https://i.pravatar.cc/150?u=david',
      timestamp: DateTime(2016, 5, 12),
      type: MediaType.photo,
      content:
          'https://images.unsplash.com/photo-1525625293386-3f8f99389edd?w=800&q=80',
      emotionEmoji: '☕',
    ),
    Moment(
      id: '2',
      authorName: 'Maya T.',
      avatarUrl: 'https://i.pravatar.cc/150?u=maya',
      timestamp: DateTime(2019, 8, 22),
      type: MediaType.photo,
      content:
          'https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800&q=80',
      emotionEmoji: '🎶',
    ),
    Moment(
      id: '3',
      authorName: 'Alex M.',
      avatarUrl: 'https://i.pravatar.cc/150?u=alex',
      timestamp: DateTime(2022, 1, 15),
      type: MediaType.photo,
      content:
          'https://images.unsplash.com/photo-1449844908441-8829872d2607?w=800&q=80',
      emotionEmoji: '🌧️',
    ),
    Moment(
      id: '4',
      authorName: 'Sarah J.',
      avatarUrl: 'https://i.pravatar.cc/150?u=sarah',
      timestamp: DateTime(2025, 10, 15),
      type: MediaType.photo,
      content:
          'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80',
      emotionEmoji: '🔥',
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Start at the most recent moment (the end of the list)
    _currentIndex = _moments.length - 1;
    _stageController = PageController(
      initialPage: _currentIndex,
      viewportFraction: 0.9,
    );
    // Set the timeline to start exactly on the correct node
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

    // 🔹 If the user swiped the Photo (not the timeline), auto-scroll the timeline to match!
    if (!_isDraggingTimeline && _timelineController.hasClients) {
      _timelineController.animateTo(
        index * _nodeWidth,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    }
  }

  String _formatDate(DateTime date) {
    // Matches your DD/MM/YYYY format from the mockup
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF2), // Scrapbook Off-White
      body: SafeArea(
        child: Column(
          children: [
            // 1. THE HEADER
            _buildHeader(),

            const SizedBox(height: 16),

            // 2. THE MAIN STAGE (Polaroid Cards)
            Expanded(
              child: PageView.builder(
                controller: _stageController,
                physics: const BouncingScrollPhysics(),
                onPageChanged: _onStagePageChanged,
                itemCount: _moments.length,
                itemBuilder: (context, index) {
                  return _buildPolaroidCard(
                    _moments[index],
                    index == _currentIndex,
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // 3. THE TIME SCRUBBER
            _buildTimeScrubber(),

            const SizedBox(height: 40),
          ],
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
          // Top Row: Back, Public Chip, Spacer
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
              Row(
                children: [
                  const Icon(Icons.public, color: Colors.black54, size: 16),
                  const SizedBox(width: 4),
                  const Text(
                    "Public",
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24), // Balance the back button
            ],
          ),

          const SizedBox(height: 24),

          // Title Row: Title & Bookmark
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.spotTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: -0.5,
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

          // Custom Divider
          Container(height: 2, width: double.infinity, color: Colors.black87),
        ],
      ),
    );
  }

  Widget _buildPolaroidCard(Moment moment, bool isSelected) {
    return AnimatedScale(
      duration: const Duration(milliseconds: 300),
      scale: isSelected ? 1.0 : 0.95,
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isSelected ? 1.0 : 0.6,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
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
              // Image Area
              Expanded(
                child: Stack(
                  children: [
                    // Main Image
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                      child: Image.network(
                        moment.content,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    ),

                    // The Diamond Icon
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.diamond_outlined,
                          color: Colors.blueAccent,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Reaction Bar
              Container(
                height: 70,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(32),
                  ),
                ),
                child: Row(
                  children: [
                    // Fake Reaction Cluster
                    const Text("😲😂", style: TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    const Text(
                      "145K",
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const Spacer(),
                    // Tap to React Call to Action
                    Text(
                      "Tap to React",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[500],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeScrubber() {
    return Column(
      children: [
        // Section Title
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

        // The Custom Draggable Track
        SizedBox(
          height: 100, // Fixed height for the interaction area
          child: LayoutBuilder(
            builder: (context, constraints) {
              // 🔹 MAGIC MATH: This padding ensures the first and last dots can reach the exact center of the screen
              final double sidePadding =
                  (constraints.maxWidth / 2) - (_nodeWidth / 2);

              return Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 1. THE SCROLLING TIMELINE TRACK
                  NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollStartNotification) {
                        _isDraggingTimeline = true;
                      } else if (notification is ScrollUpdateNotification) {
                        if (_isDraggingTimeline) {
                          // Calculate which node is closest to the center while dragging
                          int newIndex =
                              (_timelineController.offset / _nodeWidth).round();
                          newIndex = newIndex.clamp(0, _moments.length - 1);

                          if (newIndex != _currentIndex) {
                            HapticFeedback.selectionClick(); // Tactile click on every dot!
                            setState(() => _currentIndex = newIndex);
                            _stageController.jumpToPage(
                              newIndex,
                            ); // Instantly snap the photo
                          }
                        }
                      } else if (notification is ScrollEndNotification) {
                        _isDraggingTimeline = false;
                        // 🔹 When user lets go, visually "snap" the timeline to the exact center dot
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
                              // The horizontal line connecting the dots
                              Container(
                                height: 2,
                                color: Colors.grey[400],
                                // Stop the line from continuing past the first and last dots
                                margin: EdgeInsets.only(
                                  left: index == 0 ? _nodeWidth / 2 : 0,
                                  right: index == _moments.length - 1
                                      ? _nodeWidth / 2
                                      : 0,
                                ),
                              ),

                              // The Dot
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: Colors.grey[500],
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFFBFBF2),
                                    width: 2,
                                  ), // Ring effect
                                ),
                              ),

                              // '2016' Label on first dot
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

                              // 'Now' Label on last dot
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

                  // 2. THE FIXED CENTER THUMB (Blue Circle)
                  // IgnorePointer ensures the user's thumb passes *through* it to scroll the list underneath
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

                  // 3. THE FIXED CENTER DATE TEXT
                  IgnorePointer(
                    child: Positioned(
                      top: 10, // Hovers perfectly above the thumb
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
                          // The underline from your mockup
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
}
