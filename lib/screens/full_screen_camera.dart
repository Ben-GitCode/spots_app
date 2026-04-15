import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart'; // 🔹 Back to the reliable, official package!
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

  int _currentCameraIndex = 0;
  FlashMode _flashMode = FlashMode.auto;

  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _initCamera();

    // 15-second auto-stop logic
    _progressController =
        AnimationController(vsync: this, duration: const Duration(seconds: 15))
          ..addStatusListener((status) {
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

  Future<void> _initCamera({int cameraIndex = 0}) async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        if (_cameraController != null) {
          await _cameraController!.dispose();
        }

        // 🔹 ResolutionPreset.max forces the camera to use the full physical sensor,
        // which natively captures a perfect 4:3 photo!
        _cameraController = CameraController(
          _cameras![cameraIndex],
          ResolutionPreset.max,
          enableAudio: true,
        );

        await _cameraController!.initialize();
        await _cameraController!.setFlashMode(_flashMode);

        if (mounted) setState(() => _isInitialized = true);
      }
    } catch (e) {
      debugPrint("Camera Init Error: $e");
    }
  }

  // --- ACTIONS ---

  Future<void> _switchCamera() async {
    if (_cameras == null || _cameras!.length < 2) return;
    _currentCameraIndex = (_currentCameraIndex + 1) % _cameras!.length;
    setState(() => _isInitialized = false);
    await _initCamera(cameraIndex: _currentCameraIndex);
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null) return;
    if (_flashMode == FlashMode.auto) {
      _flashMode = FlashMode.always;
    } else if (_flashMode == FlashMode.always) {
      _flashMode = FlashMode.off;
    } else {
      _flashMode = FlashMode.auto;
    }
    await _cameraController!.setFlashMode(_flashMode);
    setState(() {});
  }

  Future<void> _takePhoto() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isRecording ||
        _isSaving)
      return;

    setState(() => _isSaving = true);
    HapticFeedback.heavyImpact();

    try {
      final XFile photo = await _cameraController!.takePicture();
      if (mounted) {
        _goToReviewScreen(CapturedMedia(path: photo.path, isVideo: false));
      }
    } catch (e) {
      debugPrint("Photo Error: $e");
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _startVideoRecording() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _isRecording ||
        _isSaving)
      return;

    HapticFeedback.lightImpact();
    setState(() => _isRecording = true);
    _progressController.forward(from: 0.0);

    try {
      await _cameraController!.startVideoRecording();
    } catch (e) {
      debugPrint("Video Start Error: $e");
      if (mounted) {
        setState(() => _isRecording = false);
        _progressController.stop();
      }
    }
  }

  Future<bool> _waitUntilFileIsReady(String filePath) async {
    final file = File(filePath);
    int retries = 0;
    int previousSize = -1;

    while (retries < 30) {
      if (await file.exists()) {
        final size = await file.length();
        if (size > 0 && size == previousSize) return true;
        previousSize = size;
      }
      await Future.delayed(const Duration(milliseconds: 100));
      retries++;
    }
    return false;
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
      final isReady = await _waitUntilFileIsReady(video.path);

      if (!isReady)
        throw Exception("Camera failed to finalize the video file.");

      final thumbPath = await VideoThumbnail.thumbnailFile(
        video: video.path,
        maxWidth: 600,
        quality: 75,
      );

      if (mounted) {
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
    final CapturedMedia? finalEditedMedia = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => MediaReviewScreen(media: media)),
    );

    if (finalEditedMedia == null) {
      setState(() => _isSaving = false);
    } else {
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

    final size = MediaQuery.of(context).size;
    final cameraHeight = size.width * (4 / 3); // 🔹 Mathematically perfect 3:4

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // =========================
            // 1. TOP BAR (Takes remaining space)
            // =========================
            Expanded(
              child: Container(
                color: Colors.black,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 30,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    IconButton(
                      icon: Icon(
                        _flashMode == FlashMode.always
                            ? Icons.flash_on
                            : _flashMode == FlashMode.off
                            ? Icons.flash_off
                            : Icons.flash_auto,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: _toggleFlash,
                    ),
                  ],
                ),
              ),
            ),

            // =========================
            // 2. THE CAMERA (Exact 3:4 Box)
            // =========================
            SizedBox(
              width: size.width,
              height: cameraHeight, // 🔹 Locked to exact 3:4
              child: ClipRect(
                child: FittedBox(
                  // 🔹 Because the sensor is 4:3 and the box is 3:4, this aligns 1:1 with ZERO ZOOM.
                  fit: BoxFit.cover,
                  child: SizedBox(
                    // Flips the dimensions to accommodate portrait mode
                    width: _cameraController!.value.previewSize?.height ?? 1,
                    height: _cameraController!.value.previewSize?.width ?? 1,
                    child: CameraPreview(_cameraController!),
                  ),
                ),
              ),
            ),

            // =========================
            // 3. BOTTOM BAR (Fixed 140px Height)
            // =========================
            Container(
              height: 140.0,
              color: Colors.black,
              alignment: Alignment.center,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.flip_camera_ios,
                      color: Colors.white,
                      size: 32,
                    ),
                    onPressed: _switchCamera,
                  ),

                  // The Hybrid Shutter Button
                  GestureDetector(
                    onTap: _takePhoto,
                    onLongPressStart: (_) => _startVideoRecording(),
                    onLongPressEnd: (_) => _stopVideoRecording(),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
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
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _isRecording ? 40 : 64,
                          height: _isRecording ? 40 : 64,
                          decoration: BoxDecoration(
                            color: _isRecording
                                ? Colors.redAccent
                                : Colors.white,
                            borderRadius: BorderRadius.circular(
                              _isRecording ? 8 : 32,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 48), // Balances the row
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// previous version of camera without third party package

// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:camera/camera.dart';
// import 'package:video_thumbnail/video_thumbnail.dart';
// import 'package:spots_app/screens/media_review_screen.dart';
// import 'package:spots_app/media_attachments/camera_attachment.dart';
// import 'dart:io';

// class FullScreenCameraScreen extends StatefulWidget {
//   const FullScreenCameraScreen({super.key});

//   @override
//   State<FullScreenCameraScreen> createState() => _FullScreenCameraScreenState();
// }

// class _FullScreenCameraScreenState extends State<FullScreenCameraScreen>
//     with SingleTickerProviderStateMixin {
//   CameraController? _cameraController;
//   List<CameraDescription>? _cameras;
//   bool _isInitialized = false;
//   bool _isRecording = false;
//   bool _isSaving = false;

//   // 🔹 The 15-Second Timer & Animation Controller
//   late AnimationController _progressController;

//   @override
//   void initState() {
//     super.initState();
//     _initCamera();

//     // Set up the 15-second auto-stop logic
//     _progressController =
//         AnimationController(vsync: this, duration: const Duration(seconds: 15))
//           ..addStatusListener((status) {
//             // Automatically stop recording if the 15 seconds finish
//             if (status == AnimationStatus.completed && _isRecording) {
//               _stopVideoRecording();
//             }
//           });
//   }

//   @override
//   void dispose() {
//     _cameraController?.dispose();
//     _progressController.dispose();
//     super.dispose();
//   }

//   Future<void> _initCamera() async {
//     try {
//       _cameras = await availableCameras();
//       if (_cameras != null && _cameras!.isNotEmpty) {
//         _cameraController = CameraController(
//           _cameras![0],
//           ResolutionPreset.high, // High resolution for full screen
//           enableAudio: true, // 🔹 CRITICAL: Must be true for video!
//         );

//         await _cameraController!.initialize();
//         if (mounted) setState(() => _isInitialized = true);
//       }
//     } catch (e) {
//       debugPrint("Camera Init Error: $e");
//     }
//   }

//   // --- ACTIONS ---

//   Future<void> _takePhoto() async {
//     // 🔹 Bail out if we are already recording OR saving something
//     if (_cameraController == null ||
//         !_cameraController!.value.isInitialized ||
//         _isRecording ||
//         _isSaving)
//       return;

//     setState(() => _isSaving = true); // Lock!
//     HapticFeedback.heavyImpact();

//     try {
//       final XFile photo = await _cameraController!.takePicture();
//       if (mounted) {
//         // 🔹 Route to the Review Screen!
//         _goToReviewScreen(CapturedMedia(path: photo.path, isVideo: false));
//       }
//     } catch (e) {
//       debugPrint("Photo Error: $e");
//       if (mounted) setState(() => _isSaving = false); // Unlock if it fails
//     }
//   }

//   Future<void> _startVideoRecording() async {
//     // Bail out if we are already recording OR saving something
//     if (_cameraController == null ||
//         !_cameraController!.value.isInitialized ||
//         _isRecording ||
//         _isSaving)
//       return;

//     HapticFeedback.lightImpact();

//     // 🔹 FIX 1: OPTIMISTIC START
//     // We instantly set the UI to recording BEFORE we await the slow native hardware.
//     // Now, if you let go early, the stop function knows we are trying to record!
//     setState(() => _isRecording = true);
//     _progressController.forward(from: 0.0);

//     try {
//       await _cameraController!.startVideoRecording();
//     } catch (e) {
//       debugPrint("Video Start Error: $e");
//       // If the hardware fails to start, reset the UI
//       if (mounted) {
//         setState(() => _isRecording = false);
//         _progressController.stop();
//       }
//     }
//   }

//   Future<bool> _waitUntilFileIsReady(String filePath) async {
//     final file = File(filePath);
//     int retries = 0;
//     int previousSize = -1;

//     // Check every 100ms, up to a maximum of 3 seconds (30 retries)
//     while (retries < 30) {
//       if (await file.exists()) {
//         final size = await file.length();

//         // If the file has data AND the size has stopped growing, the OS is done!
//         if (size > 0 && size == previousSize) {
//           return true;
//         }
//         previousSize = size;
//       }

//       // Wait a fraction of a second before checking again
//       await Future.delayed(const Duration(milliseconds: 100));
//       retries++;
//     }

//     return false; // Timed out (Camera likely crashed natively)
//   }

//   Future<void> _stopVideoRecording() async {
//     if (_cameraController == null || !_isRecording || _isSaving) return;

//     setState(() {
//       _isSaving = true;
//       _isRecording = false;
//     });

//     HapticFeedback.heavyImpact();
//     _progressController.stop();

//     try {
//       final XFile video = await _cameraController!.stopVideoRecording();

//       // 🔹 THE DETERMINISTIC FIX: Wait exactly as long as the hardware needs!
//       final isReady = await _waitUntilFileIsReady(video.path);

//       if (!isReady) {
//         throw Exception("The camera failed to finalize the video file.");
//       }

//       // 🔹 Now it is 100% safe to extract the thumbnail
//       final thumbPath = await VideoThumbnail.thumbnailFile(
//         video: video.path,
//         maxWidth: 600,
//         quality: 75,
//       );

//       if (mounted) {
//         _goToReviewScreen(
//           CapturedMedia(
//             path: video.path,
//             isVideo: true,
//             thumbnailPath: thumbPath,
//           ),
//         );
//       }
//     } catch (e) {
//       debugPrint("Video Stop Error: $e");
//       if (mounted) setState(() => _isSaving = false);
//     }
//   }

//   void _goToReviewScreen(CapturedMedia media) async {
//     // Push the Review Screen
//     final CapturedMedia? finalEditedMedia = await Navigator.push(
//       context,
//       MaterialPageRoute(builder: (context) => MediaReviewScreen(media: media)),
//     );

//     // If the user hits "Retake" on the review screen, it returns null.
//     // We just unlock the camera and let them try again!
//     if (finalEditedMedia == null) {
//       setState(() => _isSaving = false);
//     }
//     // If they hit "Done", we pass the edited media all the way back to the main screen!
//     else {
//       if (mounted) Navigator.pop(context, finalEditedMedia);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (!_isInitialized || _cameraController == null) {
//       return const Scaffold(
//         backgroundColor: Colors.black,
//         body: Center(child: CircularProgressIndicator(color: Colors.white)),
//       );
//     }

//     return Scaffold(
//       backgroundColor: Colors.black,
//       body: Stack(
//         fit: StackFit.expand,
//         children: [
//           // 1. The Full Screen Viewfinder
//           FittedBox(
//             fit: BoxFit.cover,
//             child: SizedBox(
//               width: _cameraController!.value.previewSize?.height ?? 1,
//               height: _cameraController!.value.previewSize?.width ?? 1,
//               child: CameraPreview(_cameraController!),
//             ),
//           ),

//           // 2. Top Bar (Close Button)
//           SafeArea(
//             child: Align(
//               alignment: Alignment.topLeft,
//               child: Padding(
//                 padding: const EdgeInsets.all(16.0),
//                 child: IconButton(
//                   icon: const Icon(Icons.close, color: Colors.white, size: 30),
//                   onPressed: () => Navigator.pop(context), // Cancel
//                   style: IconButton.styleFrom(backgroundColor: Colors.black45),
//                 ),
//               ),
//             ),
//           ),

//           // 3. The Hybrid Shutter Button
//           Align(
//             alignment: Alignment.bottomCenter,
//             child: Padding(
//               padding: const EdgeInsets.only(bottom: 40.0),
//               child: GestureDetector(
//                 onTap: _takePhoto,
//                 onLongPressStart: (_) => _startVideoRecording(),
//                 onLongPressEnd: (_) => _stopVideoRecording(),
//                 child: Stack(
//                   alignment: Alignment.center,
//                   children: [
//                     // Outer Progress Ring (Only shows when recording)
//                     SizedBox(
//                       width: 80,
//                       height: 80,
//                       child: AnimatedBuilder(
//                         animation: _progressController,
//                         builder: (context, child) {
//                           return CircularProgressIndicator(
//                             value: _isRecording
//                                 ? _progressController.value
//                                 : 0.0,
//                             strokeWidth: 5,
//                             backgroundColor: Colors.white38,
//                             valueColor: const AlwaysStoppedAnimation<Color>(
//                               Colors.redAccent,
//                             ),
//                           );
//                         },
//                       ),
//                     ),
//                     // Inner Button
//                     AnimatedContainer(
//                       duration: const Duration(milliseconds: 200),
//                       width: _isRecording ? 40 : 64,
//                       height: _isRecording ? 40 : 64,
//                       decoration: BoxDecoration(
//                         color: _isRecording ? Colors.redAccent : Colors.white,
//                         borderRadius: BorderRadius.circular(
//                           _isRecording ? 8 : 32,
//                         ), // Morphs to a square when recording
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
