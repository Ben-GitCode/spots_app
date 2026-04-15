import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:spots_app/media_attachments/media_attachment_base.dart';
import 'package:spots_app/media_attachments/poll_attachment.dart';
import 'package:spots_app/media_attachments/camera_attachment.dart';
import 'package:spots_app/media_attachments/audio_attachment.dart';
import 'package:spots_app/media_attachments/music_attachment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

//enum MediaType { text, camera, audio, music, poll, gallery }

class MediaOption {
  final String label;
  final IconData icon;
  final MediaAttachment Function() createAttachment;

  MediaOption(this.label, this.icon, this.createAttachment);
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

  // 🔹 THE MAGIC INGREDIENT: This key prevents the TextField from losing focus when moved
  final GlobalKey _textFieldKey = GlobalKey();

  final int _maxLength = 500;

  MediaAttachment? _activeAttachment;
  int _centeredIndex = 0;

  final LayerLink _privacyLayerLink = LayerLink();
  bool _isPrivacyMenuOpen = false;

  bool _isUploading = false;

  final List<PrivacyOption> _privacyOptions = [
    PrivacyOption('1', 'Public', PrivacyLevel.public, icon: Icons.public),
    PrivacyOption('2', 'Me', PrivacyLevel.me, icon: Icons.lock_outline),
    PrivacyOption('3', 'Sigmas', PrivacyLevel.group, icon: Icons.group),
    PrivacyOption('4', 'Family', PrivacyLevel.group, icon: Icons.group),
    PrivacyOption('5', 'Ma Wife', PrivacyLevel.group, icon: Icons.group),
  ];

  late PrivacyOption _selectedPrivacy;
  late final List<MediaOption> _mediaOptions;

  @override
  void initState() {
    super.initState();
    _selectedPrivacy = _privacyOptions[0];

    _mediaOptions = [
      MediaOption(
        "Camera",
        Icons.camera_alt_outlined,
        () => CameraAttachment(),
      ),
      MediaOption("Audio", Icons.mic_none, () => AudioAttachment()),
      MediaOption("Music", Icons.music_note_outlined, () => MusicAttachment()),
      MediaOption("Poll", Icons.poll_outlined, () => PollAttachment()),
    ];

    Future.delayed(const Duration(milliseconds: 100), () {
      _focusNode.requestFocus();
    });

    _textController.addListener(_updateUI);
  }

  void _updateUI() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _textController.removeListener(_updateUI);
    _textController.dispose();
    _focusNode.dispose();

    _activeAttachment?.removeListener(_updateUI);
    _activeAttachment?.dispose();
    super.dispose();
  }

  void _onMediaTapped() async {
    HapticFeedback.mediumImpact();

    // 1. Create the attachment but don't set it as active yet
    final pendingAttachment = _mediaOptions[_centeredIndex].createAttachment();

    // 2. Wait for it to do its thing (e.g., open full-screen camera)
    final bool keep = await pendingAttachment.onSelected(context);

    // 3. If the user cancelled the camera, throw the attachment away
    if (!keep) {
      pendingAttachment.dispose();
      return;
    }

    // 4. If successful, lock it in as the active attachment!
    setState(() {
      _activeAttachment?.removeListener(_updateUI);
      _activeAttachment?.dispose();

      _activeAttachment = pendingAttachment;
      _activeAttachment?.addListener(_updateUI);
    });

    _focusNode.requestFocus();
  }

  void _onDiscardMedia() {
    HapticFeedback.lightImpact();

    setState(() {
      _activeAttachment?.removeListener(_updateUI);
      _activeAttachment?.dispose();
      _activeAttachment = null;
    });

    // 🔹 Force the keyboard to stay open when returning to normal
    _focusNode.requestFocus();
  }

  bool _isReadyToCapture() {
    bool textReady = _textController.text.trim().isNotEmpty;
    bool mediaReady = _activeAttachment?.isValid ?? false;

    if (_activeAttachment != null) {
      if (_activeAttachment!.requiresText) {
        return textReady && mediaReady;
      }
      return textReady || mediaReady;
    }

    return textReady;
  }

  Future<void> _uploadAndSaveMoment() async {
    setState(() => _isUploading = true);
    HapticFeedback.heavyImpact();

    try {
      final supabase = Supabase.instance.client;
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) throw Exception("User must be logged in to post.");

      // 1. INSTANT GPS LOCK
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      Map<String, dynamic>? finalMediaPayload = null;

      if (_activeAttachment != null) {
        final rawJson = Map<String, dynamic>.from(_activeAttachment!.toJson());
        final String type = rawJson['type'] ?? 'text';

        if (type == 'image' || type == 'video' || type == 'audio') {
          // --- UPLOADABLE MEDIA ---
          final localPath = rawJson['path'] as String?;
          if (localPath != null) {
            final file = File(localPath);
            if (!await file.exists()) throw Exception("Local file not found.");

            // 🔹 NEW: Check the exact byte size of the file on the phone
            final int fileSize = await file.length();
            debugPrint("🚨 PRE-UPLOAD FILE SIZE: $fileSize bytes");

            if (fileSize == 0) {
              throw Exception(
                "The video file is 0 bytes! The camera hasn't finished writing it to disk.",
              );
            }

            // 🔹 Decoupled Naming: Timestamp + 4 random characters guarantees uniqueness in the bucket
            final fileExtension = localPath.split('.').last;
            final timestamp = DateTime.now().millisecondsSinceEpoch;
            final storagePath = '$userId/$timestamp.$fileExtension';

            // Upload the file to the 'moment_storage' bucket
            await supabase.storage
                .from('moment_media')
                .upload(storagePath, file);

            // Grab the public URL
            final publicUrl = supabase.storage
                .from('moment_media')
                .getPublicUrl(storagePath);

            // --- 2. UPLOAD THUMBNAIL (IF IT EXISTS) ---
            String? thumbnailUrl;
            final thumbPath =
                rawJson['thumbnail']
                    as String?; // Extracted from your CameraAttachment!

            if (thumbPath != null && thumbPath.isNotEmpty) {
              final thumbFile = File(thumbPath);
              if (await thumbFile.exists()) {
                final thumbExtension = thumbPath.split('.').last;
                // Append '_thumb' so it lives right next to the main file in the bucket
                final thumbStoragePath =
                    '$userId/${timestamp}_thumb.$thumbExtension';

                await supabase.storage
                    .from('moment_media')
                    .upload(thumbStoragePath, thumbFile);

                thumbnailUrl = supabase.storage
                    .from('moment_media')
                    .getPublicUrl(thumbStoragePath);
              }
            }

            // --- 3. BUILD THE JSON PAYLOAD ---
            if (type == 'audio') {
              finalMediaPayload = {
                'type': 'audio',
                'title': rawJson['title'] ?? 'Voice Note',
                'duration': rawJson['duration'] ?? '0:00',
                'url': publicUrl,
              };
            } else {
              // This dynamically handles both 'photo' and 'video'
              finalMediaPayload = {'type': type, 'url': publicUrl};

              // Only inject the thumbnail key if we successfully uploaded one!
              if (thumbnailUrl != null) {
                finalMediaPayload['thumbnail_url'] = thumbnailUrl;
              }
            }
          }
        } else if (type == 'music') {
          // --- ODESLI API INTEGRATION ---
          final String originalUrl = rawJson['url'];
          final encodedUrl = Uri.encodeComponent(originalUrl);

          final odesliRes = await http.get(
            Uri.parse('https://api.song.link/v1-alpha.1/links?url=$encodedUrl'),
          );

          if (odesliRes.statusCode == 200) {
            final odesliData = json.decode(odesliRes.body);
            final entityUniqueId = odesliData['entityUniqueId'];
            final entitiesByUniqueId = odesliData['entitiesByUniqueId'];
            final linksByPlatform = odesliData['linksByPlatform'];

            final primaryEntity = entitiesByUniqueId[entityUniqueId];

            Map<String, String> platformLinks = {};
            if (linksByPlatform.containsKey('spotify'))
              platformLinks['Spotify'] = linksByPlatform['spotify']['url'];
            if (linksByPlatform.containsKey('appleMusic'))
              platformLinks['Apple Music'] =
                  linksByPlatform['appleMusic']['url'];
            if (linksByPlatform.containsKey('youtubeMusic'))
              platformLinks['YouTube Music'] =
                  linksByPlatform['youtubeMusic']['url'];

            finalMediaPayload = {
              'type': 'music',
              'song_title': primaryEntity['title'] ?? 'Unknown Title',
              'artist': primaryEntity['artistName'] ?? 'Unknown Artist',
              'album_art': primaryEntity['thumbnailUrl'] ?? '',
              'preview_url': originalUrl,
              'platform_links': platformLinks,
            };
          } else {
            throw Exception("Could not fetch song data from Odesli.");
          }
        } else if (type == 'poll') {
          // --- POLL DATA ---
          finalMediaPayload = {'type': 'poll', 'options': rawJson['options']};
        }
      }

      // 4. THE RPC CALL
      await supabase.rpc(
        'create_moment_with_spot',
        params: {
          'p_caption': _textController.text.trim(),
          'p_media_payload': finalMediaPayload,
          'p_lat': position.latitude,
          'p_lng': position.longitude,
        },
      );

      debugPrint("Successfully created moment!");

      HapticFeedback.lightImpact();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      debugPrint("Upload Failed: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to post moment: $e"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
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

    final bool isTopLayout = _activeAttachment?.isTopLayout ?? false;
    final String hintText =
        _activeAttachment?.hintText ?? "What happened here?...";

    // 1. The Text Widget (Now wrapped in AnimatedPadding with ValueKey)
    Widget textFieldWidget = AnimatedPadding(
      key: const ValueKey('text_widget_wrapper'),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.fromLTRB(
        16.0,
        isTopLayout ? 16.0 : 0,
        16.0,
        isTopLayout ? 0 : 8.0,
      ),
      child: TextField(
        key: _textFieldKey, // 🔹 Prevents widget destruction, preserving focus!
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
          hintText: hintText,
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

    // 2. The Media Widget (Now wrapped in AnimatedPadding with ValueKey)
    Widget mediaSlotWidget = AnimatedPadding(
      key: const ValueKey('media_widget_wrapper'),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.all(12.0),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: _activeAttachment == null
            ? _buildMediaSelectionWheel()
            : _buildActiveMediaSlot(),
      ),
    );

    // 🔹 The Swapper: Determines rendering order
    List<Widget> scrollableContent = isTopLayout
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

                  Expanded(
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        // 🔹 FIX 1: Added bottom padding so it never sits flush with the keyboard!
                        padding: const EdgeInsets.only(
                          left: 24.0,
                          right: 24.0,
                          bottom: 15.0,
                        ),
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
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 30,
                                spreadRadius:
                                    5, // Spreads the shadow outward past the edges
                                offset: const Offset(0, 15),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => _focusNode.requestFocus(),
                                  behavior: HitTestBehavior.opaque,
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: scrollableContent,
                                    ),
                                  ),
                                ),
                              ),

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
                                        // 🔹 Disable the tap if uploading OR not ready
                                        onTap: (canCapture && !_isUploading)
                                            ? _uploadAndSaveMoment
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
                                          // 🔹 Swap text for a spinner during upload!
                                          child: _isUploading
                                              ? const SizedBox(
                                                  width: 18,
                                                  height: 18,
                                                  child:
                                                      CircularProgressIndicator(
                                                        color: Colors.white,
                                                        strokeWidth: 2.5,
                                                      ),
                                                )
                                              : Text(
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

  Widget _buildActiveMediaSlot() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E2A),
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          if (_activeAttachment != null)
            _activeAttachment!.buildEditor(context),

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
}
