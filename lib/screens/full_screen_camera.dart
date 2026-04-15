import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camerawesome/camerawesome_plugin.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:spots_app/screens/media_review_screen.dart';
import 'package:spots_app/media_attachments/camera_attachment.dart';

class FullScreenCameraScreen extends StatefulWidget {
  const FullScreenCameraScreen({super.key});

  @override
  State<FullScreenCameraScreen> createState() => _FullScreenCameraScreenState();
}

class _FullScreenCameraScreenState extends State<FullScreenCameraScreen> {
  bool _isRouting = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          Colors.black, // Forces the letterboxed borders to be pure black
      // 🔹 SWAPPED TO .custom()! We now have 100% control of the UI layout
      body: CameraAwesomeBuilder.custom(
        sensorConfig: SensorConfig.single(
          sensor: Sensor.position(SensorPosition.back),
          flashMode: FlashMode.auto,
          aspectRatio: CameraAspectRatios.ratio_4_3, // Under-the-hood 4:3 lock
        ),
        saveConfig: SaveConfig.photoAndVideo(
          initialCaptureMode: CaptureMode.photo,
          photoPathBuilder: (sensors) async {
            final dir = await getTemporaryDirectory();
            final ext = DateTime.now().millisecondsSinceEpoch;
            return SingleCaptureRequest(
              '${dir.path}/photo_$ext.jpg',
              sensors.first,
            );
          },
          videoPathBuilder: (sensors) async {
            final dir = await getTemporaryDirectory();
            final ext = DateTime.now().millisecondsSinceEpoch;
            return SingleCaptureRequest(
              '${dir.path}/video_$ext.mp4',
              sensors.first,
            );
          },
        ),

        // 🔹 1. Tell the background camera to gracefully letterbox itself!
        previewFit: CameraPreviewFit.contain,

        // 🔹 THE CAPTURE HOOK
        onMediaCaptureEvent: (event) async {
          if (event.status == MediaCaptureStatus.success && !_isRouting) {
            _isRouting = true;
            HapticFeedback.heavyImpact();

            event.captureRequest.when(
              single: (single) async {
                final String path = single.file!.path;
                final bool isVideo = path.endsWith('.mp4');
                String? thumbPath;

                if (isVideo) {
                  thumbPath = await VideoThumbnail.thumbnailFile(
                    video: path,
                    maxWidth: 600,
                    quality: 75,
                  );
                }

                if (mounted) {
                  final CapturedMedia? editedMedia = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MediaReviewScreen(
                        media: CapturedMedia(
                          path: path,
                          isVideo: isVideo,
                          thumbnailPath: thumbPath,
                        ),
                      ),
                    ),
                  );

                  if (editedMedia == null) {
                    _isRouting = false;
                  } else {
                    if (mounted) Navigator.pop(context, editedMedia);
                  }
                }
              },
              multiple: (multiple) {},
            );
          }
        },

        // ==========================================
        // 🔹 2. THE CUSTOM UI BUILDER
        // ==========================================
        builder: (cameraState, previewInfo) {
          // We use a Column to physically stack the UI over the background camera.
          return Column(
            children: [
              // --- 1. TOP BAR ---
              Container(
                color:
                    Colors.black, // Opaque black covers the top letterbox area
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 8.0,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Far Left: Exit
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 30,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),

                        // Center: Custom 15-second Video Limiter
                        if (cameraState is VideoRecordingCameraState)
                          Video15sLimiter(state: cameraState)
                        else
                          const SizedBox(),

                        // Far Right: Flash (Moved away from the X!)
                        AwesomeFlashButton(state: cameraState),
                      ],
                    ),
                  ),
                ),
              ),

              // --- 2. THE VIEWFINDER (Transparent Hole) ---
              // 🔹 The camera is automatically drawn behind this empty space!
              const Expanded(child: SizedBox()),

              // --- 3. BOTTOM BAR ---
              Container(
                color: Colors
                    .black, // Opaque black covers the bottom letterbox area
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24.0, top: 12.0),
                    child: Column(
                      children: [
                        // The Photo / Video Text Slider
                        AwesomeCameraModeSelector(state: cameraState),
                        const SizedBox(height: 20),

                        // The Shutter Controls
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            AwesomeCameraSwitchButton(
                              state: cameraState,
                            ), // Selfie Switcher
                            AwesomeCaptureButton(state: cameraState), // Shutter
                            const SizedBox(
                              width: 48,
                            ), // Empty space balances the row! No Gallery button!
                          ],
                        ),
                      ],
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
}

// ============================================================================
// 🔹 THE MAGIC LIMITER WIDGET (Custom 15s Timer UI)
// ============================================================================
class Video15sLimiter extends StatefulWidget {
  final VideoRecordingCameraState state;
  const Video15sLimiter({super.key, required this.state});

  @override
  State<Video15sLimiter> createState() => _Video15sLimiterState();
}

class _Video15sLimiterState extends State<Video15sLimiter> {
  Timer? _stopTimer;
  Timer? _uiTimer;
  int _secondsRecorded = 0;
  bool _isBlinking = true;

  @override
  void initState() {
    super.initState();

    // Hard Cutoff: Forces the hardware to stop at 15 seconds
    _stopTimer = Timer(const Duration(seconds: 15), () {
      widget.state.stopRecording();
    });

    // UI Ticker: Updates text & blinks dot every second
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_secondsRecorded < 15) {
            _secondsRecorded++;
          }
          _isBlinking = !_isBlinking;
        });
      }
    });
  }

  @override
  void dispose() {
    _stopTimer?.cancel();
    _uiTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String secondsStr = _secondsRecorded.toString().padLeft(2, '0');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedOpacity(
            opacity: _isBlinking ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 400),
            child: const Icon(Icons.circle, color: Colors.redAccent, size: 10),
          ),
          const SizedBox(width: 8),
          Text(
            "00:$secondsStr / 00:15",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 1.0,
            ),
          ),
        ],
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
