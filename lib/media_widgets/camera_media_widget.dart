import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:camera/camera.dart';

class CameraMediaWidget extends StatefulWidget {
  // 🔹 The callback that passes the photo path back to the main screen
  final Function(String? imagePath) onPhotoCaptured;

  const CameraMediaWidget({super.key, required this.onPhotoCaptured});

  @override
  State<CameraMediaWidget> createState() => _CameraMediaWidgetState();
}

class _CameraMediaWidgetState extends State<CameraMediaWidget> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  XFile? _capturedImage;
  bool _isCameraInitialized = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
  }

  @override
  void dispose() {
    // Clean up the hardware when this widget is closed!
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        // ResolutionPreset.medium keeps the UI fluid and upload sizes manageable
        _cameraController = CameraController(
          _cameras![0],
          ResolutionPreset.medium,
          enableAudio: false, // We only want photos here
        );

        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      debugPrint("Camera Init Error: $e");
    }
  }

  Future<void> _takePicture() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized)
      return;
    HapticFeedback.heavyImpact();

    try {
      final XFile picture = await _cameraController!.takePicture();
      setState(() => _capturedImage = picture);

      // 🔹 Send the file path back up to the parent screen!
      widget.onPhotoCaptured(picture.path);
    } catch (e) {
      debugPrint("Take Picture Error: $e");
    }
  }

  void _retakePicture() {
    HapticFeedback.lightImpact();
    setState(() => _capturedImage = null);

    // 🔹 Tell the parent screen to clear the media state
    widget.onPhotoCaptured(null);
  }

  @override
  Widget build(BuildContext context) {
    if (!_isCameraInitialized || _cameraController == null) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Live Viewfinder
        if (_capturedImage == null)
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _cameraController!.value.previewSize?.height ?? 1,
              height: _cameraController!.value.previewSize?.width ?? 1,
              child: CameraPreview(_cameraController!),
            ),
          ),

        // 2. Captured Image Display
        if (_capturedImage != null)
          Image.file(File(_capturedImage!.path), fit: BoxFit.cover),

        // 3. Shutter / Retake Button
        Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: _capturedImage == null ? _takePicture : _retakePicture,
              child: Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  color: _capturedImage != null
                      ? Colors.black45
                      : Colors.white54,
                ),
                child: _capturedImage != null
                    ? const Icon(Icons.refresh, color: Colors.white, size: 20)
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
