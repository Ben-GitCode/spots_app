import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spots_app/media_widgets/audio_media_widget.dart';
import 'package:spots_app/media_widgets/camera_media_widget.dart';
import 'package:spots_app/media_widgets/full_screen_camera.dart';
import 'package:spots_app/media_widgets/poll_media_widget.dart';

enum MediaType { text, camera, audio, music, poll, gallery }

class MediaOption {
  final MediaType type;
  final String label;
  final IconData icon;
  MediaOption(this.type, this.label, this.icon);
}

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

  final List<MediaOption> _mediaOptions = [
    MediaOption(MediaType.camera, "Camera", Icons.camera_alt_outlined),
    MediaOption(MediaType.audio, "Record", Icons.mic_none),
    MediaOption(MediaType.music, "Music", Icons.music_note_outlined),
    MediaOption(MediaType.poll, "Poll", Icons.poll_outlined),
  ];

  int _centeredIndex = 0;
  MediaType? _selectedMedia;
  dynamic _finalMediaData;

  final LayerLink _privacyLayerLink = LayerLink();
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
    _selectedPrivacy = _privacyOptions[0];

    // Automatically open keyboard
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

  void _onMediaTapped() async {
    HapticFeedback.mediumImpact();
    final selected = _mediaOptions[_centeredIndex].type;

    if (selected == MediaType.camera) {
      final CapturedMedia? result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const FullScreenCameraScreen()),
      );

      if (result != null) {
        setState(() {
          _selectedMedia = MediaType.camera;
          _finalMediaData = result;
        });
      }
    } else {
      setState(() => _selectedMedia = selected);
    }
  }

  void _onDiscardMedia() {
    HapticFeedback.lightImpact();
    setState(() {
      _selectedMedia = null;
      _finalMediaData = null;
    });
  }

  // 🔹 SMART CAPTURE LOGIC
  bool _isReadyToCapture() {
    bool textReady = _textController.text.trim().isNotEmpty;
    bool mediaReady = _finalMediaData != null;

    if (_selectedMedia == MediaType.poll) {
      // 🔹 Polls REQUIRE both a question (text) and valid options (media)
      return textReady && mediaReady;
    }

    // For everything else, either text OR media is fine
    return textReady || mediaReady;
  }

  Color _getPrivacyColor(PrivacyLevel level) {
    switch (level) {
      case PrivacyLevel.public:
        return const Color(0xFF6A9FB5);
      case PrivacyLevel.me:
        return const Color(0xFFF6C954);
      case PrivacyLevel.group:
        return const Color(0xFF9ECA42);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canCapture = _isReadyToCapture();
    final int charCount = _textController.text.length;

    final double screenWidth = MediaQuery.of(context).size.width;
    final double cardWidth = screenWidth - 48;
    final double mediaSlotSize = cardWidth - 24;
    final double targetCardHeight = mediaSlotSize + 140;

    // 🔹 DYNAMIC UX PROPERTIES
    final bool isPoll = _selectedMedia == MediaType.poll;
    final String hintText = isPoll
        ? "Ask a question..."
        : "What happened here?...";

    // 1. The Text Widget
    Widget textFieldWidget = Padding(
      padding: EdgeInsets.fromLTRB(
        16.0,
        isPoll ? 16.0 : 0,
        16.0,
        isPoll ? 0 : 8.0,
      ),
      child: TextField(
        controller: _textController,
        focusNode: _focusNode,
        maxLines: null,
        minLines: 2,
        keyboardType: TextInputType.multiline,
        maxLength: _maxLength,
        style: const TextStyle(
          fontSize: 18,
          color: Colors.black87,
          height: 1.3,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: hintText, // 🔹 Dynamic Hint!
          hintStyle: TextStyle(
            color: Colors.black.withOpacity(0.25),
            fontSize: 18,
          ),
          border: InputBorder.none,
          counterText: "",
          isDense: true,
        ),
      ),
    );

    // 2. The Media Widget
    Widget mediaSlotWidget = Padding(
      padding: const EdgeInsets.all(12.0),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _selectedMedia == null
            ? _buildMediaSelectionWheel()
            : _buildActiveMediaSlot(mediaSlotSize),
      ),
    );

    // 🔹 The Swapper: Determines rendering order based on media type!
    List<Widget> scrollableContent = isPoll
        ? [textFieldWidget, mediaSlotWidget]
        : [mediaSlotWidget, textFieldWidget];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFBCE3E8), Color(0xFFDCA8D4), Color(0xFFD6CBB0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.4, 1.0],
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            SafeArea(
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

                  // B. THE SMART VIEWPORT POLAROID
                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        child: Container(
                          constraints: BoxConstraints(
                            maxHeight: targetCardHeight,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDFBF7),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white, width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 40,
                                offset: const Offset(0, 20),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // 1. SCROLLABLE INNER CONTENT (Dynamically Swapped!)
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _focusNode.requestFocus(),
                                  behavior: HitTestBehavior.opaque,
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      // 🔹 Instantly swaps the layout!
                                      children: scrollableContent,
                                    ),
                                  ),
                                ),
                              ),

                              // 2. PINNED FOOTER
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 12.0,
                                  right: 12.0,
                                  bottom: 12.0,
                                  top: 4.0,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    CompositedTransformTarget(
                                      link: _privacyLayerLink,
                                      child: _buildPrivacyToggleButton(),
                                    ),
                                    const Spacer(),
                                    Padding(
                                      padding: const EdgeInsets.only(
                                        right: 12.0,
                                      ),
                                      child: Text(
                                        '$charCount/$_maxLength',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: (_maxLength - charCount) <= 20
                                              ? Colors.redAccent
                                              : Colors.grey[400],
                                        ),
                                      ),
                                    ),
                                    Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: canCapture
                                            ? () {
                                                HapticFeedback.heavyImpact();
                                                Navigator.pop(context);
                                              }
                                            : null,
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 20,
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            gradient: canCapture
                                                ? const LinearGradient(
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                    colors: [
                                                      Color(0xFF3A5A78),
                                                      Color(0xFF1E3246),
                                                    ],
                                                  )
                                                : null,
                                            color: canCapture
                                                ? null
                                                : Colors.black.withOpacity(0.1),
                                          ),
                                          child: Text(
                                            "Capture",
                                            style: TextStyle(
                                              color: canCapture
                                                  ? Colors.white
                                                  : Colors.black26,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
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
                  ),
                ],
              ),
            ),

            // 🔹 PRIVACY MENU OVERLAY
            if (_isPrivacyMenuOpen) ...[
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _isPrivacyMenuOpen = false),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Color.fromARGB(255, 0, 0, 0),
                          Color.fromARGB(100, 0, 0, 0),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                  ),
                ),
              ),
              CompositedTransformFollower(
                link: _privacyLayerLink,
                targetAnchor: Alignment.topLeft,
                followerAnchor: Alignment.bottomLeft,
                offset: const Offset(0, -12),
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

  Widget _buildActiveMediaSlot(double squareSize) {
    final bool isCamera = _selectedMedia == MediaType.camera;
    final bool hasCapturedMedia = isCamera && _finalMediaData is CapturedMedia;

    return Container(
      width: double.infinity,
      height: isCamera ? squareSize : null,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            height: isCamera ? squareSize : null,
            child: isCamera && hasCapturedMedia
                ? Image.file(
                    File(
                      (_finalMediaData as CapturedMedia).isVideo
                          ? (_finalMediaData as CapturedMedia).thumbnailPath!
                          : (_finalMediaData as CapturedMedia).path,
                    ),
                    fit: BoxFit.cover,
                  )
                : _buildSpecificMediaUI(),
          ),

          if (isCamera &&
              hasCapturedMedia &&
              (_finalMediaData as CapturedMedia).isVideo)
            Positioned.fill(
              child: Container(
                color: Colors.black26,
                child: const Center(
                  child: Icon(
                    Icons.play_circle_fill,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),

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

  Widget _buildSpecificMediaUI() {
    switch (_selectedMedia) {
      case MediaType.audio:
        return AudioMediaWidget(
          onAudioCaptured: (String path) =>
              setState(() => _finalMediaData = path),
        );
      case MediaType.poll:
        return PollMediaWidget(
          onPollUpdated: (optionsList) =>
              setState(() => _finalMediaData = optionsList),
        );
      default:
        return const SizedBox();
    }
  }

  // --- PRIVACY COMPONENT BUILDERS ---

  Widget _buildPrivacyToggleButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _isPrivacyMenuOpen = !_isPrivacyMenuOpen);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.07),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedPrivacy.icon != null) ...[
              Icon(_selectedPrivacy.icon, color: Colors.black54, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              _selectedPrivacy.label,
              style: const TextStyle(
                color: Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyMenu() {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.35,
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
            GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
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
            const SizedBox(height: 16),
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

  Widget _buildMediaSelectionWheel() {
    return Container(
      key: const ValueKey('selection_wheel'),
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF141418),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.black38, width: 1.5),
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _mediaOptions.length,
        itemBuilder: (context, index) {
          final option = _mediaOptions[index];
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _centeredIndex = index);
              _onMediaTapped();
            },
            child: Container(
              width: 87,
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(option.icon, color: Colors.white, size: 36),
                  const SizedBox(height: 12),
                  Text(
                    option.label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
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
}
