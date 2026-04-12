import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spots_app/utils/user_data.dart';

class UserProvider extends ChangeNotifier {
  UserData? _currentUser;
  bool _isLoading = false;

  UserData? get currentUser => _currentUser;
  bool get isLoading => _isLoading;

  final _supabase = Supabase.instance.client;

  // This is the "Magic" function that fixes your null error
  Future<void> refreshUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Fetch profile data from your Supabase 'profiles' table
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', user.id)
          .single();

      //_currentUser = UserData.fromJson(data);
    } catch (e) {
      debugPrint("Error refreshing user: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Use this to manually update the state (e.g., after an edit profile)
  void setUser(UserData user) {
    _currentUser = user;
    notifyListeners();
  }

  // Call this when the user logs out
  void clearUser() {
    _currentUser = null;
    notifyListeners();
  }
}