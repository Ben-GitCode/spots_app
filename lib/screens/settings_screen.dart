import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:spots_app/providers/user_provider.dart';
import 'onboarding_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                _buildSectionTitle('Account'),
                ListTile(
                  leading: const Icon(Icons.person_outline),
                  title: const Text('Edit Profile'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () { /* Navigate to profile edit */ },
                ),
                ListTile(
                  leading: const Icon(Icons.emoji_events_outlined),
                  title: const Text('Achievements'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () { /* Navigate to achievements */ },
                ),
                
                const Divider(),
                _buildSectionTitle('Preferences'),
                SwitchListTile(
                  secondary: const Icon(Icons.notifications_none),
                  title: const Text('Push Notifications'),
                  value: _notificationsEnabled,
                  onChanged: (bool value) => setState(() => _notificationsEnabled = value),
                ),
                SwitchListTile(
                  secondary: const Icon(Icons.dark_mode_outlined),
                  title: const Text('Dark Mode'),
                  value: _darkMode,
                  onChanged: (bool value) => setState(() => _darkMode = value),
                ),
                
                const Divider(),
                _buildSectionTitle('Support'),
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Help Center'),
                  onTap: () { /* Open help URL */ },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('About App'),
                  subtitle: const Text('Version 1.0.4'),
                ),
              ],
            ),
          ),
          
          // The Logout Button Section
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () => _showLogoutDialog(context),
                child: const Text(
                  'Log Out',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey[600],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Log Out?'),
        content: const Text('Are you sure you want to log out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              context.read<UserProvider>().logout();
              if (mounted) {
                // 2. Navigate and clear history
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const SpotsOnboardingScreen()),
                  (route) => false, // This 'false' ensures all previous routes are removed
                );
              }
            },
            child: const Text('Log Out', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}