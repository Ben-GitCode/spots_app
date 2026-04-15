import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioMediaWidget extends StatefulWidget {
  // 🔹 FIX: The callback now passes BOTH the path and the formatted duration!
  final Function(String audioPath, String durationFormatted) onAudioCaptured;

  const AudioMediaWidget({super.key, required this.onAudioCaptured});

  @override
  State<AudioMediaWidget> createState() => _AudioMediaWidgetState();
}

class _AudioMediaWidgetState extends State<AudioMediaWidget>
    with SingleTickerProviderStateMixin {
  final AudioRecorder _audioRecorder = AudioRecorder();
  String? _audioPath;
  bool _isRecording = false;
  int _recordDuration = 0;
  Timer? _recordTimer;
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
    _audioRecorder.dispose();
    _recordTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    HapticFeedback.heavyImpact();

    if (_isRecording) {
      final path = await _audioRecorder.stop();
      _recordTimer?.cancel();

      // 🔹 Format the duration string right before we stop
      String minutes = (_recordDuration ~/ 60).toString();
      String seconds = (_recordDuration % 60).toString().padLeft(2, '0');
      String finalDuration = "$minutes:$seconds";

      setState(() {
        _isRecording = false;
        _audioPath = path;
      });

      // 🔹 Send BOTH pieces of data back up to the parent screen!
      if (path != null) {
        widget.onAudioCaptured(path, finalDuration);
      }
    } else {
      if (await _audioRecorder.hasPermission()) {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/moment_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: path);

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
          _audioPath = null;
        });

        _recordTimer = Timer.periodic(
          const Duration(seconds: 1),
          (t) => setState(() => _recordDuration++),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String minutes = (_recordDuration ~/ 60).toString().padLeft(2, '0');
    String seconds = (_recordDuration % 60).toString().padLeft(2, '0');

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: _audioPath == null ? _toggleRecording : null,
            child: AnimatedBuilder(
              animation: _pulseController,
              builder: (context, child) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _audioPath != null
                        ? Colors.greenAccent.withOpacity(0.2)
                        : (_isRecording
                              ? Colors.redAccent.withOpacity(
                                  0.2 + (_pulseController.value * 0.3),
                                )
                              : Colors.white12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _audioPath != null
                        ? Icons.check
                        : (_isRecording ? Icons.stop_rounded : Icons.mic),
                    color: _audioPath != null
                        ? Colors.greenAccent
                        : (_isRecording ? Colors.redAccent : Colors.white),
                    size: 32,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _audioPath != null
                ? "Audio Captured"
                : (_recordDuration > 0 ? "$minutes:$seconds" : "Tap to Record"),
            style: TextStyle(
              color: _audioPath != null
                  ? Colors.greenAccent
                  : (_isRecording ? Colors.redAccent : Colors.white54),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}
