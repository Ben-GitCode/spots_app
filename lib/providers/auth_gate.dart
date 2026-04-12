import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../screens/login_screen.dart';
import '../screens/map_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // This listens to the current session from Supabase
    final session = Supabase.instance.client.auth.currentSession;

    // If there is a session, go straight to the Map
    if (session != null) {
      return const MapScreen();
    }

    // Otherwise, show the Login screen
    return const LoginScreen();
  }
}