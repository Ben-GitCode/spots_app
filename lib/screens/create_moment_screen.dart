import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spots_app/media_widgets/audio_media_widget.dart';
import 'package:spots_app/media_widgets/camera_media_widget.dart';
import 'package:spots_app/media_widgets/poll_media_widget.dart';

// --- ENUMS & DATA MODELS ---
// This makes it trivial to add new media types later!
enum MediaType { text, camera, audio, music, poll, gallery }

class MediaOption {
  final MediaType type;
  final String label;
  final IconData icon;

  MediaOption(this.type, this.label, this.icon);
}

// 🔹 Added Privacy Models
enum PrivacyLevel { public, me, group }

class PrivacyOption {
  final String id;
  final String label;
  final PrivacyLevel level;
  final IconData? icon;

  PrivacyOption(this.id, this.label, this.level, {this.icon});
}

class CreateMomentScreen extends StatefulWidget {
  const CreateMomentScreen({super.key});

  @override
  State<CreateMomentScreen> createState() => _CreateMomentScreenState();
}

class _CreateMomentScreenState extends State<CreateMomentScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final int _maxLength = 500;

  // The available media types
  final List<MediaOption> _mediaOptions = [
    MediaOption(MediaType.camera, "Camera", Icons.camera_alt_outlined),
    MediaOption(MediaType.audio, "Record", Icons.mic_none),
    MediaOption(MediaType.music, "Music", Icons.music_note_outlined),
    MediaOption(MediaType.poll, "Poll", Icons.poll_outlined),
  ];

  // State Variables
  int _centeredIndex = 0; // Which item is currently in the middle of the wheel
  MediaType? _selectedMedia; // The media type the user actually tapped on

  dynamic _finalMediaData; // Will hold the XFile, Audio Path, or Poll Data

  // 🔹 Privacy State Variables
  final LayerLink _privacyLayerLink =
      LayerLink(); // Links the menu to the button
  bool _isPrivacyMenuOpen = false;

  final List<PrivacyOption> _privacyOptions = [
    PrivacyOption('1', 'Public', PrivacyLevel.public, icon: Icons.public),
    PrivacyOption('2', 'Me', PrivacyLevel.me, icon: Icons.lock_outline),
    PrivacyOption('3', 'Sigmas', PrivacyLevel.group, icon: Icons.group),
    PrivacyOption('4', 'Family', PrivacyLevel.group, icon: Icons.group),
    PrivacyOption('5', 'Ma Wife', PrivacyLevel.group, icon: Icons.group),
  ];

  late PrivacyOption _selectedPrivacy;

  @override
  void initState() {
    super.initState();

    _selectedPrivacy = _privacyOptions[0]; // Default to Public

    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
    });
    _textController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // --- ACTIONS ---

  void _onMediaTapped() {
    HapticFeedback.mediumImpact();
    setState(() {
      // Lock in the media type that was currently centered in the wheel
      _selectedMedia = _mediaOptions[_centeredIndex].type;
    });
  }

  void _onDiscardMedia() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMedia = null; // Revert back to the selection wheel
      _finalMediaData = null; // 🔹 ADD THIS: Clear the actual data!
    });
  }

  // 🔹 ADD THIS METHOD
  bool _isReadyToCapture() {
    bool textReady = _textController.text.trim().isNotEmpty;
    bool mediaReady =
        _finalMediaData != null; // True only if a photo/audio/poll is finished!
    return textReady || mediaReady;
  }

  // 🔹 Color Logic for Privacy Options
  Color _getPrivacyColor(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.public:
        return const Color(0xFF6A9FB5); // Premium Blue
      case PrivacyLevel.me:
        return const Color(0xFFF6C954); // Yellow
      case PrivacyLevel.group:
        return const Color(0xFF9ECA42); // Vibrant Green
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasText = _textController.text.trim().isNotEmpty;
    final int charCount = _textController.text.length;
    final bool canCapture = _isReadyToCapture();

    return Container(
      decoration: const BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFBCE3E8), // Muted, sophisticated light blue
            Color(0xFFDCA8D4), // Dusty, romantic pink
            Color(0xFFD6CBB0), // Deeper, grounded sand/champagne
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.4, 1.0], // Smoother, longer transitions
        ),
      ),
      // 2. THE SCAFFOLD SITS ON TOP, COMPLETELY TRANSPARENT
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // 2. MAIN CONTENT
            SafeArea(
              // Wrapped the whole screen in a SingleChildScrollView so small screens don't overflow
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: SizedBox(
                  // We calculate the available screen height minus the keyboard height to ensure the button is always visible
                  height:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top -
                      MediaQuery.of(context).padding.bottom -
                      MediaQuery.of(context).viewInsets.bottom,
                  child: Column(
                    children: [
                      // A. TOP BAR
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: const Text(
                                "Cancel",
                                style: TextStyle(
                                  color: Colors.black87,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // B. THE TACTILE POLAROID CARD
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        // 🔹 FIX 1: REMOVED "Expanded" and gave it a strict height of 420.
                        // Now it will NEVER stretch, but everything inside still scrolls!
                        child: SizedBox(
                          height: 350,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // The Card Itself
                              Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFDFBF7),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 1.5,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 40,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    // 🔹 SCROLLABLE CONTENT AREA
                                    Expanded(
                                      child: SingleChildScrollView(
                                        physics: const BouncingScrollPhysics(),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          children: [
                                            // Dynamic Media Slot
                                            Padding(
                                              padding: const EdgeInsets.all(
                                                12.0,
                                              ),
                                              child: AnimatedSwitcher(
                                                duration: const Duration(
                                                  milliseconds: 300,
                                                ),
                                                switchInCurve:
                                                    Curves.easeOutCubic,
                                                switchOutCurve: Curves.easeIn,
                                                child: _selectedMedia == null
                                                    ? _buildMediaSelectionWheel()
                                                    : _buildActiveMediaSlot(),
                                              ),
                                            ),

                                            // Text Input
                                            Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 16.0,
                                                    vertical: 8.0,
                                                  ),
                                              child: TextField(
                                                controller: _textController,
                                                focusNode: _focusNode,
                                                maxLines: null,
                                                keyboardType:
                                                    TextInputType.multiline,
                                                maxLength: _maxLength,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  color: Colors.black87,
                                                  height: 1.3,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                                decoration: InputDecoration(
                                                  hintText:
                                                      "What happened here?...",
                                                  hintStyle: TextStyle(
                                                    color: Colors.black
                                                        .withOpacity(0.25),
                                                    fontSize: 18,
                                                  ),
                                                  border: InputBorder.none,
                                                  counterText: "",
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    // 🔹 FIXED FOOTER AREA (Privacy Button & Counter perfectly balanced)
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        left: 16.0,
                                        right: 16.0,
                                        bottom: 16.0,
                                        top: 8.0,
                                      ),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          // Left: Subtle Privacy Chip
                                          CompositedTransformTarget(
                                            link: _privacyLayerLink,
                                            child: _buildPrivacyToggleButton(),
                                          ),
                                          // Right: Character Counter
                                          Text(
                                            '$charCount/$_maxLength',
                                            textAlign: TextAlign.right,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  (_maxLength - charCount) <= 20
                                                  ? Colors.redAccent
                                                  : Colors.grey[400],
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

                      // 🔹 This Spacer absorbs the extra screen height, pushing the Capture button down
                      const Spacer(),

                      // C. BOTTOM ACTION BAR
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 12.0,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: canCapture
                                    ? const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          // Color(0xFF6B4A5F), // Rich, muted plum
                                          // Color(0xFF3D2635), // Deep blackberry
                                          Color(0xFF3A5A78), // Deep slate blue
                                          Color(0xFF1E3246), // Dark navy
                                        ],
                                        // colors: [
                                        //   Color(0xFF91C5F2),
                                        //   Color(0xFFF2A7E6),
                                        // ],
                                      )
                                    : null,
                                color: canCapture
                                    ? null
                                    : Colors.black.withValues(alpha: 0.3),
                                boxShadow: canCapture
                                    ? [
                                        BoxShadow(
                                          color: const Color(
                                            0xFF3A5A78,
                                          ).withValues(alpha: 0.5),
                                          blurRadius: 15,
                                          offset: const Offset(0, 5),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(24),
                                  onTap: canCapture
                                      ? () {
                                          HapticFeedback.heavyImpact();
                                          // TODO: Upload _finalMediaData to Supabase!
                                          Navigator.pop(context);
                                        }
                                      : null,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 28,
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      "Capture",
                                      style: TextStyle(
                                        color: canCapture
                                            ? Colors.white
                                            : Colors.black26,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
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

            // 🔹 3. FULL-SCREEN DARK OVERLAY & MENU
            if (_isPrivacyMenuOpen) ...[
              // The Dark Dimming Layer (Keeps keyboard open!)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _isPrivacyMenuOpen = false),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color.fromARGB(255, 0, 0, 0),
                          Color.fromARGB(100, 0, 0, 0),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    // color: Colors.black.withOpacity(
                    //   0.5,
                    // ), // Semi-transparent dark overlay
                  ),
                ),
              ),
              // The Menu Overlay
              CompositedTransformFollower(
                link: _privacyLayerLink,
                targetAnchor: Alignment.topLeft,
                followerAnchor: Alignment.bottomLeft,
                offset: const Offset(
                  0,
                  -12,
                ), // Hovers perfectly above the button
                child: Material(
                  color: Colors.transparent,
                  child: _buildPrivacyMenu(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // --- PRIVACY COMPONENT BUILDERS ---

  Widget _buildPrivacyToggleButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isPrivacyMenuOpen = !_isPrivacyMenuOpen);
      },
      // 🔹 The "Ghost" Button UX: Subtle, flat, and doesn't compete with Capture
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withValues(
            alpha: 0.07,
          ), // Very subtle grey background
          borderRadius: BorderRadius.circular(8), // Softer, less "pill-like"
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedPrivacy.icon != null) ...[
              Icon(
                _selectedPrivacy.icon,
                color: Colors.black54, // Muted icon
                size: 16,
              ),
              const SizedBox(width: 6),
            ],
            Text(
              _selectedPrivacy.label,
              style: const TextStyle(
                color: Colors.black54, // Muted text
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            // const SizedBox(width: 4),
            // const Icon(
            //   Icons.keyboard_arrow_down,
            //   color: Colors.black38,
            //   size: 14,
            // ), // Adds a tiny arrow so users know it's a dropdown
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyMenu() {
    // 🔹 Dynamic and Scrollable Menu Container
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight:
            MediaQuery.of(context).size.height *
            0.35, // Ensures it doesn't run off screen
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuPill(_privacyOptions[0]),
            const SizedBox(height: 8),
            _buildMenuPill(_privacyOptions[1]),
            const SizedBox(height: 16),
            const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.people_alt_outlined,
                  color: Colors.white70,
                  size: 18,
                ),
                SizedBox(width: 8),
                Text(
                  "Private Groups",
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildMenuPill(_privacyOptions[2]),
            const SizedBox(height: 8),
            _buildMenuPill(_privacyOptions[3]),
            const SizedBox(height: 8),
            _buildMenuPill(_privacyOptions[4]),
            const SizedBox(height: 12),

            // New Group Button
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                // TODO: Open Create Group Flow
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, color: Colors.black87, size: 18),
                    SizedBox(width: 6),
                    Text(
                      "New Group",
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16), // Bottom padding
          ],
        ),
      ),
    );
  }

  Widget _buildMenuPill(PrivacyOption option) {
    final isSelected = _selectedPrivacy.id == option.id;
    final Color bgColor = isSelected
        ? _getPrivacyColor(option.level)
        : const Color.fromARGB(255, 122, 128, 137);

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedPrivacy = option;
          _isPrivacyMenuOpen = false;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(color: Colors.white24, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (option.icon != null) ...[
              Icon(option.icon, color: Colors.white, size: 18),
              const SizedBox(width: 6),
            ],
            Text(
              option.label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- COMPONENT BUILDERS ---

  Widget _buildMediaSelectionWheel() {
    return Container(
      key: const ValueKey('selection_wheel'),
      height: 140,
      decoration: BoxDecoration(
        color: Color(0xFF141418),
        borderRadius: BorderRadius.circular(8),
        // 🔹 FIX: We must use a uniform border when using borderRadius!
        border: Border.all(color: Colors.black38, width: 1.5),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _mediaOptions.length,
        itemBuilder: (context, index) {
          final option = _mediaOptions[index];
          //final isSelected = index == _centeredIndex;

          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _centeredIndex = index);
              _onMediaTapped();
              // if (isSelected) {
              //   // Lock it in if already selected
              //   _onMediaTapped();
              // } else {
              //   // Highlight the tapped item
              //   HapticFeedback.selectionClick();
              //   setState(() => _centeredIndex = index);
              // }
            },
            child: Container(
              width: 87, // Strict width constraint
              color: Colors.transparent, // Keeps the whole area tappable
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Size and opacity changed instantly
                  Icon(
                    option.icon,
                    color: Colors.white,
                    size: 36,
                    // color: isSelected ? Colors.white : Colors.white38,
                    // size: isSelected ? 36 : 28,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    option.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      // color: isSelected ? Colors.white : Colors.white38,
                      // fontWeight: isSelected
                      //     ? FontWeight.bold
                      //     : FontWeight.w500,
                      // fontSize: isSelected ? 13 : 11,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActiveMediaSlot() {
    return Container(
      key: const ValueKey('active_media'),
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // 1. The Dynamic Media Content
          Positioned.fill(child: _buildSpecificMediaUI()),

          // 2. The Red 'X' Discard Button
          Positioned(
            top: 8,
            right: 8,
            child: GestureDetector(
              onTap: _onDiscardMedia,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.redAccent[400],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // A generic router that returns the correct UI based on what was selected
  // Inside CreateMomentScreen

  Widget _buildSpecificMediaUI() {
    switch (_selectedMedia) {
      case MediaType.camera:
        return CameraMediaWidget(
          onPhotoCaptured: (path) {
            setState(() => _finalMediaData = path);
          },
        );

      case MediaType.audio:
        return AudioMediaWidget(
          onAudioCaptured: (String path) {
            setState(() => _finalMediaData = path);
          },
        );

      case MediaType.poll:
        return PollMediaWidget(
          onPollUpdated: (optionsList) {
            setState(() => _finalMediaData = optionsList);
          },
        );

      default:
        return const SizedBox();
    }
  }
}
