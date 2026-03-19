import 'package:flutter/material.dart';

class PollMediaWidget extends StatefulWidget {
  // 🔹 The callback that passes the poll data back to the main screen.
  // It passes a List of strings if valid, or null if incomplete.
  final Function(List<String>? pollOptions) onPollUpdated;

  const PollMediaWidget({super.key, required this.onPollUpdated});

  @override
  State<PollMediaWidget> createState() => _PollMediaWidgetState();
}

class _PollMediaWidgetState extends State<PollMediaWidget> {
  final TextEditingController _opt1Controller = TextEditingController();
  final TextEditingController _opt2Controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listeners so every keystroke evaluates the poll's validity
    _opt1Controller.addListener(_evaluatePoll);
    _opt2Controller.addListener(_evaluatePoll);
  }

  @override
  void dispose() {
    _opt1Controller.dispose();
    _opt2Controller.dispose();
    super.dispose();
  }

  void _evaluatePoll() {
    final opt1 = _opt1Controller.text.trim();
    final opt2 = _opt2Controller.text.trim();

    // Only send data back if BOTH fields have text
    if (opt1.isNotEmpty && opt2.isNotEmpty) {
      widget.onPollUpdated([opt1, opt2]);
    } else {
      // If they delete text and make it invalid, send null to disable the Capture button
      widget.onPollUpdated(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Extra right padding so the text doesn't hide behind the red 'X' close button
      padding: const EdgeInsets.fromLTRB(16, 20, 36, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildPollTextField(_opt1Controller, "Option 1 (e.g. Yes)"),
          const SizedBox(height: 8),
          _buildPollTextField(_opt2Controller, "Option 2 (e.g. No)"),
        ],
      ),
    );
  }

  Widget _buildPollTextField(TextEditingController controller, String hint) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(
            color: Colors.white.withOpacity(0.3),
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }
}
