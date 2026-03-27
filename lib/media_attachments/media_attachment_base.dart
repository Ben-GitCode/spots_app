import 'package:flutter/material.dart';

abstract class MediaAttachment extends ChangeNotifier {
  String get hintText;
  bool get isValid;
  bool get requiresText => false;
  bool get isTopLayout => false;

  // 🔹 NEW: Allows the attachment to do async work (like opening a full screen)
  // before locking in. Returns true if successful, false if cancelled.
  Future<bool> onSelected(BuildContext context) async => true;

  // The actual widget to display in the create moment screen
  Widget buildEditor(BuildContext context);

  // Packages the data to be sent to your backend (e.g., Supabase)
  Map<String, dynamic> toJson();
}
