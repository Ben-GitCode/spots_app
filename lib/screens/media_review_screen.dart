import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'package:spots_app/media_widgets/camera_media_widget.dart';

class MediaReviewScreen extends StatefulWidget {
  final CapturedMedia media;
  const MediaReviewScreen({super.key, required this.media});

  @override
  State<MediaReviewScreen> createState() => _MediaReviewScreenState();
}

class _MediaReviewScreenState extends State<MediaReviewScreen> {
  final Trimmer _trimmer = Trimmer();
  bool _isVideoLoaded = false;
  bool _isPlaying = false;
  bool _isSaving = false;

  double _startValue = 0.0;
  double _endValue = 0.0;

  @override
  void initState() {
    super.initState();
    if (widget.media.isVideo) {
      _loadVideo();
    }
  }

  Future<void> _loadVideo() async {
    // 🔹 This loads the file and triggers the native thumbnail extraction
    await _trimmer.loadVideo(videoFile: File(widget.media.path));

    if (mounted) {
      setState(() => _isVideoLoaded = true);

      _trimmer.videoPlayerController?.addListener(() {
        final isPlaying =
            _trimmer.videoPlayerController?.value.isPlaying ?? false;
        if (mounted && _isPlaying != isPlaying) {
          setState(() => _isPlaying = isPlaying);
        }
      });
    }
  }

  @override
  void dispose() {
    if (widget.media.isVideo) _trimmer.dispose();
    super.dispose();
  }

  Future<void> _saveVideoAndFinish() async {
    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      onSave: (String? outputPath) {
        if (mounted) {
          setState(() => _isSaving = false);
          if (outputPath != null) {
            Navigator.pop(
              context,
              CapturedMedia(
                path: outputPath,
                isVideo: true,
                thumbnailPath: widget.media.thumbnailPath,
              ),
            );
          }
        }
      },
    );
  }

  Future<void> _togglePlayback() async {
    HapticFeedback.lightImpact();
    final controller = _trimmer.videoPlayerController;
    if (controller != null) {
      if (_isPlaying) {
        controller.pause();
        setState(() => _isPlaying = false);
      } else {
        // 🔹 Smart Auto-Rewind if we hit the end!
        final currentPos = await controller.position;
        if (currentPos != null &&
            currentPos.inMilliseconds >= _endValue.toInt() - 150) {
          await controller.seekTo(Duration(milliseconds: _startValue.toInt()));
        }
        controller.play();
        setState(() => _isPlaying = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Media Preview
            Expanded(
              child: Center(
                child: widget.media.isVideo
                    ? (_isVideoLoaded
                          ? GestureDetector(
                              onTap: _togglePlayback,
                              child: VideoViewer(trimmer: _trimmer),
                            )
                          : const CircularProgressIndicator(
                              color: Colors.white,
                            ))
                    : Image.file(File(widget.media.path), fit: BoxFit.contain),
              ),
            ),

            // 2. Video Trimmer Timeline
            if (widget.media.isVideo && _isVideoLoaded)
              Container(
                height: 80,
                color: const Color(0xFF1E1E2A),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    // 🔹 Explicitly pass the constraints to prevent invisible rendering bugs!
                    return TrimViewer(
                      trimmer: _trimmer,
                      viewerHeight: 50.0,
                      viewerWidth: constraints.maxWidth,
                      onChangeStart: (value) => _startValue = value,
                      onChangeEnd: (value) => _endValue = value,
                      onChangePlaybackState: (value) =>
                          setState(() => _isPlaying = value),
                    );
                  },
                ),
              ),

            // 3. Action Bar
            Container(
              padding: const EdgeInsets.only(
                bottom: 16,
                top: 16,
                left: 24,
                right: 24,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            HapticFeedback.lightImpact();
                            Navigator.pop(context, null);
                          },
                    child: const Text(
                      "Retake",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  if (widget.media.isVideo && _isVideoLoaded)
                    GestureDetector(
                      onTap: _togglePlayback,
                      child: Icon(
                        _isPlaying
                            ? Icons.pause_circle_filled
                            : Icons.play_circle_fill,
                        color: Colors.white,
                        size: 48,
                      ),
                    )
                  else if (!widget.media.isVideo)
                    const Spacer(),

                  TextButton(
                    onPressed: _isSaving
                        ? null
                        : () {
                            if (widget.media.isVideo) {
                              _saveVideoAndFinish();
                            } else {
                              HapticFeedback.heavyImpact();
                              Navigator.pop(context, widget.media);
                            }
                          },
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFFE8B647),
                              strokeWidth: 3,
                            ),
                          )
                        : const Text(
                            "Done",
                            style: TextStyle(
                              color: Color(0xFFE8B647),
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
