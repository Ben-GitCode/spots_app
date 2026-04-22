import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:spots_app/media_attachments/media_attachment_base.dart';

// ==========================================
// 1. THE BRAINS (State, Logic, Validation)
// ==========================================
class AudioAttachment extends MediaAttachment {
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _recordTimer;

  // Public getters so the UI can read the state
  String? audioPath;
  bool isRecording = false;
  int recordDuration = 0;
  bool isPlaying = false;

  AudioAttachment() {
    // Automatically reset the Play/Pause button when the audio finishes playing
    _audioPlayer.onPlayerComplete.listen((_) {
      isPlaying = false;
      notifyListeners();
    });
  }

  Future<void> toggleRecording() async {
    HapticFeedback.heavyImpact();
    if (isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final tempDir = await getTemporaryDirectory();
      final path =
          '${tempDir.path}/moment_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(const RecordConfig(), path: path);

      isRecording = true;
      recordDuration = 0;
      audioPath = null;
      notifyListeners(); // Update UI to show red recording state

      // 🔹 Start the timer and enforce the 15-second limit
      _recordTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        recordDuration++;
        if (recordDuration >= 15) {
          _stopRecording(); // Automatically cut off at 15s!
        } else {
          notifyListeners();
        }
      });
    }
  }

  Future<void> _stopRecording() async {
    final path = await _audioRecorder.stop();
    _recordTimer?.cancel();

    isRecording = false;
    audioPath = path;
    notifyListeners(); // Trigger the Review UI to appear
  }

  // 🔹 Playback Control
  Future<void> togglePlayback() async {
    if (audioPath == null) return;
    HapticFeedback.lightImpact();

    if (isPlaying) {
      await _audioPlayer.pause();
      isPlaying = false;
    } else {
      await _audioPlayer.play(DeviceFileSource(audioPath!));
      isPlaying = true;
    }
    notifyListeners();
  }

  // 🔹 Discard & Retake
  void discardAudio() {
    HapticFeedback.lightImpact();
    _audioPlayer.stop(); // Stop playing if they discard mid-listen
    audioPath = null;
    recordDuration = 0;
    isPlaying = false;
    notifyListeners();
  }

  // --- INTERFACE REQUIREMENTS ---

  @override
  String get hintText => "What happened here?...";

  @override
  bool get requiresText => false;

  @override
  bool get isTopLayout => false;

  @override
  bool get isValid => audioPath != null && !isRecording;

  @override
  Map<String, dynamic> toJson() {
    // 🔹 FIX: Format the exact duration and pass it to the uploader!
    String seconds = recordDuration.toString().padLeft(2, '0');

    return {'type': 'audio', 'path': audioPath, 'duration': '0:$seconds'};
  }

  @override
  void dispose() {
    _recordTimer?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget buildEditor(BuildContext context) {
    return _AudioEditorUI(attachment: this);
  }
}

// ==========================================
// 2. THE LOOKS (Animation & UI rendering)
// ==========================================
class _AudioEditorUI extends StatefulWidget {
  final AudioAttachment attachment;

  const _AudioEditorUI({required this.attachment});

  @override
  State<_AudioEditorUI> createState() => _AudioEditorUIState();
}

class _AudioEditorUIState extends State<_AudioEditorUI>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.attachment,
      builder: (context, child) {
        final att = widget.attachment;
        String seconds = att.recordDuration.toString().padLeft(2, '0');

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          child: Center(
            child: att.audioPath != null
                ? _buildPlaybackUI(att)
                : _buildRecordingUI(att, seconds),
          ),
        );
      },
    );
  }

  // 🔹 State 1: Before / During Recording
  Widget _buildRecordingUI(AudioAttachment att, String seconds) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: att.toggleRecording,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: att.isRecording
                      ? Colors.redAccent.withOpacity(
                          0.2 + (_pulseController.value * 0.3),
                        )
                      : Colors.white12,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  att.isRecording ? Icons.stop_rounded : Icons.mic,
                  color: att.isRecording ? Colors.redAccent : Colors.white,
                  size: 32,
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          att.recordDuration > 0 ? "00:$seconds / 00:15" : "Tap to Record",
          style: TextStyle(
            color: att.isRecording ? Colors.redAccent : Colors.white54,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  // 🔹 State 2: After Capture (Review & Playback)
  Widget _buildPlaybackUI(AudioAttachment att) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Play/Pause Button
            GestureDetector(
              onTap: att.togglePlayback,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  att.isPlaying
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Colors.greenAccent,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(width: 24),
            // Discard/Retake Button
            GestureDetector(
              onTap: att.discardAudio,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  color: Colors.white12,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.white54,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          "Ready to Post",
          style: TextStyle(
            color: Colors.greenAccent,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
