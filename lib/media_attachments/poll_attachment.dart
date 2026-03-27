import 'package:flutter/material.dart';
import 'media_attachment_base.dart';

class PollAttachment extends MediaAttachment {
  final List<TextEditingController> _controllers = [];
  final int _maxOptions = 4;

  PollAttachment() {
    _addOption();
    _addOption();
  }

  void _addOption() {
    if (_controllers.length < _maxOptions) {
      final controller = TextEditingController();
      controller.addListener(notifyListeners);
      _controllers.add(controller);
      notifyListeners();
    }
  }

  void _removeOption(int index) {
    if (_controllers.length <= 2) {
      _controllers[index].clear();
    } else {
      final removedController = _controllers.removeAt(index);
      removedController.removeListener(notifyListeners);
      removedController.dispose();
      notifyListeners();
    }
  }

  @override
  String get hintText => "Ask a question...";

  @override
  bool get isValid => _controllers.every((c) => c.text.trim().isNotEmpty);

  @override
  bool get requiresText => true; // Forces the user to type a question for polls

  @override
  bool get isTopLayout => true; // Puts the poll UI above the text box

  @override
  Map<String, dynamic> toJson() {
    return {
      'type': 'poll',
      'options': _controllers.map((c) => c.text.trim()).toList(),
    };
  }

  @override
  void dispose() {
    // 1. Grab a copy of the controllers so we can dispose them safely later
    final controllersToDispose = List<TextEditingController>.from(_controllers);

    // 2. Immediately stop listening so they don't trigger state changes during the animation
    for (var controller in controllersToDispose) {
      controller.removeListener(notifyListeners);
    }

    // 3. Delay the actual destruction to let the AnimatedSize finish its 300ms shrink
    Future.delayed(const Duration(milliseconds: 350), () {
      for (var controller in controllersToDispose) {
        controller.dispose();
      }
    });

    super.dispose();
  }

  // --- THE UI IS NOW INLINED HERE ---
  @override
  Widget buildEditor(BuildContext context) {
    // ListenableBuilder ensures only this UI block rebuilds when typing or adding options
    return ListenableBuilder(
      listenable: this,
      builder: (context, child) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 36, 16),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...List.generate(_controllers.length, (index) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: _buildPollTextField(index),
                  );
                }),
                if (_controllers.length < _maxOptions) _buildAddOptionButton(),
              ],
            ),
          ),
        );
      },
    );
  }

  // UI Helper Methods can live right here in the same class
  Widget _buildPollTextField(int index) {
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
          GestureDetector(
            onTap: () => _removeOption(index),
            child: Container(
              padding: const EdgeInsets.all(12),
              color: Colors.transparent,
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
      onTap: _addOption,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1.5),
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
