import 'dart:io';
import 'package:flutter/material.dart';
import 'package:spots_app/screens/full_screen_camera.dart';
import 'package:spots_app/media_attachments/media_attachment_base.dart';

// 🔹 Moved here so everything can access it
class CapturedMedia {
  final String path;
  final bool isVideo;
  final String? thumbnailPath;

  CapturedMedia({
    required this.path,
    required this.isVideo,
    this.thumbnailPath,
  });
}

class CameraAttachment extends MediaAttachment {
  CapturedMedia? _media;

  // 🔹 Intercept the selection to open your full-screen camera!
  @override
  Future<bool> onSelected(BuildContext context) async {
    final CapturedMedia? result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FullScreenCameraScreen()),
    );

    if (result != null) {
      _media = result;
      return true; // Keep the attachment!
    }
    return false; // User hit cancel on the camera, discard attachment.
  }

  @override
  String get hintText => "What happened here?...";

  @override
  bool get requiresText => false;

  @override
  bool get isTopLayout => false;

  @override
  bool get isValid => _media != null;

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': _media!.isVideo ? 'video' : 'image',
      'path': _media!.path,
      'thumbnail': _media!.thumbnailPath,
    };
  }

  @override
  Widget buildEditor(BuildContext context) {
    if (_media == null) return const SizedBox();

    // 🔹 Automatic Square Crop UI
    // Using AspectRatio + BoxFit.cover visually crops the 16:9 media into a perfect square
    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.file(
            File(_media!.isVideo ? _media!.thumbnailPath! : _media!.path),
            fit: BoxFit.cover,
          ),

          // Show a play button overlay if it's a video
          if (_media!.isVideo)
            Container(
              color: Colors.black26,
              child: const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
