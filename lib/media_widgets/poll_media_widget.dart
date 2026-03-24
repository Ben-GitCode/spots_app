import 'package:flutter/material.dart';

class PollMediaWidget extends StatefulWidget {
  // 🔹 The callback passes a List of strings if valid (min 2), or null if incomplete.
  final Function(List<String>? pollOptions) onPollUpdated;

  const PollMediaWidget({super.key, required this.onPollUpdated});

  @override
  State<PollMediaWidget> createState() => _PollMediaWidgetState();
}

class _PollMediaWidgetState extends State<PollMediaWidget> {
  // We use a dynamic list of controllers to handle 2 to 4 options
  final List<TextEditingController> _controllers = [];
  final int _maxOptions = 4;

  @override
  void initState() {
    super.initState();
    // Initialize with exactly 2 mandatory options
    _addController();
    _addController();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  // Helper to safely add a new controller and bind its listener
  void _addController() {
    final controller = TextEditingController();
    controller.addListener(_evaluatePoll);
    _controllers.add(controller);
  }

  void _evaluatePoll() {
    // Extract non-empty trimmed strings from all controllers
    final validOptions = _controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    // The Capture button should only light up if we have AT LEAST 2 valid options
    if (validatePollOptions(_controllers)) {
      widget.onPollUpdated(validOptions);
    } else {
      widget.onPollUpdated(null);
    }
  }

  bool validatePollOptions(List<TextEditingController> optionControllers) {
    // Checks that every visible controller has non-empty text
    return optionControllers.every(
      (controller) => controller.text.trim().isNotEmpty,
    );
  }

  void _addNewOption() {
    if (_controllers.length < _maxOptions) {
      setState(() {
        _addController();
      });
      // We don't need to manually evaluate here because the new field is empty
    }
  }

  void _removeOption(int index) {
    setState(() {
      if (_controllers.length <= 2) {
        // If there are only 2 options left, just clear the text instead of deleting the field
        _controllers[index].clear();
      } else {
        // If there are > 2 options, destroy the text field entirely and shift the rest up
        final removedController = _controllers.removeAt(index);
        removedController.dispose();

        // We MUST re-evaluate because an option containing text might have been deleted
        _evaluatePoll();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      // Padding ensures it doesn't overlap the red "X" discard button on the top right
      padding: const EdgeInsets.fromLTRB(16, 24, 36, 16),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Generate the list of current TextFields
            ...List.generate(_controllers.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: _buildPollTextField(index),
              );
            }),

            // If we haven't hit the max limit, show the 'Add Option' button
            if (_controllers.length < _maxOptions) _buildAddOptionButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildPollTextField(int index) {
    // Determine the dynamic hint text
    String hint = "Option ${index + 1}";
    if (index == 0 && _controllers[0].text.isEmpty) hint += " (e.g. Yes)";
    if (index == 1 && _controllers[1].text.isEmpty) hint += " (e.g. No)";

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controllers[index],
              style: const TextStyle(color: Colors.white, fontSize: 15),
              textCapitalization: TextCapitalization.sentences,
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
          ),

          // The "X" Delete Button
          GestureDetector(
            onTap: () => _removeOption(index),
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors
                  .transparent, // Keeps the tap target large but invisible
              child: Icon(
                Icons.close,
                color: Colors.white.withOpacity(0.5),
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddOptionButton() {
    return GestureDetector(
      onTap: _addNewOption,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withOpacity(0.2), // Subtle dashed-look outline
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: Colors.white.withOpacity(0.6), size: 20),
            const SizedBox(width: 8),
            Text(
              "Add Option",
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
