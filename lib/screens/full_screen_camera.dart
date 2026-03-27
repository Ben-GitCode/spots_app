import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:spots_app/screens/media_review_screen.dart';
import 'package:spots_app/media_attachments/camera_attachment.dart';

class FullScreenCameraScreen extends StatefulWidget {
  const FullScreenCameraScreen({super.key});

  @override
  State<FullScreenCameraScreen> createState() => _FullScreenCameraScreenState();
}

class _FullScreenCameraScreenState extends State<FullScreenCameraScreen>
    with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isRecording = false;
  bool _isSaving = false;

  // 🔹 The 15-Second Timer & Animation Controller
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _initCamera();

    // Set up the 15-second auto-stop logic
    _progressController =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..addStatusListener((status) {
            // Automatically stop recording if the 15 seconds finish
            if (status == AnimationStatus.completed && _isRecording) {
              _stopVideoRecording();
            }
          });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.high, // High resolution for full screen
          enableAudio: true, // 🔹 CRITICAL: Must be true for video!
        );

        await _cameraController!.initialize();
        if (mounted) setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera Init Error: $e");
    }
  }

  // --- ACTIONS ---

  Future<void> _takePhoto() async {
    // 🔹 Bail out if we are already recording OR saving something
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isRecording ||
        _isSaving)
      return;

    setState(() => _isSaving = true); // Lock!
    HapticFeedback.heavyImpact();

    try {
      final XFile photo = await _cameraController!.takePicture();
      if (mounted) {
        // 🔹 Route to the Review Screen!
        _goToReviewScreen(CapturedMedia(path: photo.path, isVideo: false));
      }
    } catch (e) {
      debugPrint("Photo Error: $e");
      if (mounted) setState(() => _isSaving = false); // Unlock if it fails
    }
  }

  Future<void> _startVideoRecording() async {
    // Bail out if we are already recording OR saving something
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isRecording ||
        _isSaving)
      return;

    HapticFeedback.lightImpact();

    // 🔹 FIX 1: OPTIMISTIC START
    // We instantly set the UI to recording BEFORE we await the slow native hardware.
    // Now, if you let go early, the stop function knows we are trying to record!
    setState(() => _isRecording = true);
    _progressController.forward(from: 0.0);

    try {
      await _cameraController!.startVideoRecording();
    } catch (e) {
      debugPrint("Video Start Error: $e");
      // If the hardware fails to start, reset the UI
      if (mounted) {
        setState(() => _isRecording = false);
        _progressController.stop();
      }
    }
  }

  Future<void> _stopVideoRecording() async {
    if (_cameraController == null || !_isRecording || _isSaving) return;

    setState(() {
      _isSaving = true;
      _isRecording = false;
    });

    HapticFeedback.heavyImpact();
    _progressController.stop();

    try {
      final XFile video = await _cameraController!.stopVideoRecording();

      // 🔹 MAGIC HAPPENS HERE: Extract the first frame!
      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: video.path,
        maxWidth: 600, // Keeps memory usage low
        quality: 75,
      );

      if (mounted) {
        // Instead of popping directly to the main screen, we route to the Review Screen!
        _goToReviewScreen(
          CapturedMedia(
            path: video.path,
            isVideo: true,
            thumbnailPath: thumbPath,
          ),
        );
      }
    } catch (e) {
      debugPrint("Video Stop Error: $e");
      if (mounted) setState(() => _isSaving = false);
    }
  }

  void _goToReviewScreen(CapturedMedia media) async {
    // Push the Review Screen
    final CapturedMedia? finalEditedMedia = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MediaReviewScreen(media: media)),
    );

    // If the user hits "Retake" on the review screen, it returns null.
    // We just unlock the camera and let them try again!
    if (finalEditedMedia == null) {
      setState(() => _isSaving = false);
    }
    // If they hit "Done", we pass the edited media all the way back to the main screen!
    else {
      if (mounted) Navigator.pop(context, finalEditedMedia);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized || _cameraController == null) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. The Full Screen Viewfinder
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.height ?? 1,
              height: _cameraController!.value.previewSize?.width ?? 1,
              child: CameraPreview(_cameraController!),
            ),
          ),

          // 2. Top Bar (Close Button)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context), // Cancel
                  style: IconButton.styleFrom(backgroundColor: Colors.black45),
                ),
              ),
            ),
          ),

          // 3. The Hybrid Shutter Button
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40.0),
              child: GestureDetector(
                onTap: _takePhoto,
                onLongPressStart: (_) => _startVideoRecording(),
                onLongPressEnd: (_) => _stopVideoRecording(),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer Progress Ring (Only shows when recording)
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, child) {
                          return CircularProgressIndicator(
                            value: _isRecording
                                ? _progressController.value
                                : 0.0,
                            strokeWidth: 5,
                            backgroundColor: Colors.white38,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.redAccent,
                            ),
                          );
                        },
                      ),
                    ),
                    // Inner Button
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: _isRecording ? 40 : 64,
                      height: _isRecording ? 40 : 64,
                      decoration: BoxDecoration(
                        color: _isRecording ? Colors.redAccent : Colors.white,
                        borderRadius: BorderRadius.circular(
                          _isRecording ? 8 : 32,
                        ), // Morphs to a square when recording
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
