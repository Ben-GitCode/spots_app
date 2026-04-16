import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'map_screen.dart';
import 'package:spots_app/utils/user_data.dart';
import 'package:provider/provider.dart';
import 'package:spots_app/providers/user_provider.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  File? _imageFile;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  /// 📸 1. Open the System Camera (Photo Only)
  Future<void> _openCustomCamera() async {
    // This triggers the native device camera directly
    final XFile? photo = await _picker.pickImage(
      source: ImageSource.camera, // 🔹 Forces the camera to open
      imageQuality: 80,           // 🔹 Compresses slightly for faster Supabase upload
      preferredCameraDevice: CameraDevice.front, // Optional: default to selfie cam
    );

    if (photo != null) {
      setState(() {
        _imageFile = File(photo.path);
      });
    }
  }

  /// 🖼️ 2. Open System Gallery
  Future<void> _pickFromGallery() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70, // Compress slightly for faster uploads
    );
    
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  /// ☁️ 3. Upload to Supabase & Finish
  Future<void> _completeSetup() async {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    try {
      // 1. Determine the Image URL
      String? imageUrl;
      const String defaultUrl = "https://nyprkwgliwnyktcqsfsf.supabase.co/storage/v1/object/public/profile_pictures/wanderercreative-blank-profile-picture-973460_640.png";

      if (_imageFile != null && user != null) {
        final fileName = '${user.id}_profile.jpg';
        
        await supabase.storage.from('profile_pictures').upload(
          fileName,
          _imageFile!,
          //fileOptions: const FileOptions(upsert: true),
        );

        imageUrl = supabase.storage.from('profile_pictures').getPublicUrl(fileName);
      } else {
        // If no image was picked, use your default
        imageUrl = defaultUrl;
      }

      // 2. Update Supabase Auth Metadata
      await supabase.auth.updateUser(
        UserAttributes(data: {'profile_picture_url': imageUrl}),
      );

      // 3. Call your Postgres Function (RPC)
      // Make sure 'create_user_profile' exists in your Database -> Functions
      final String username = user?.userMetadata?['name'] ?? "New User";
      
      await supabase.rpc('create_user_profile', params: {
        'p_username': username,
        'p_profile_picture': imageUrl,
      });

      // 3. Initialize your UserData class
      // Note: 'user.userMetadata' contains the name from the Signup screen
      final newUserData = UserData(
        id: user!.id,
        username: username,
        profilePictureUrl: imageUrl,
        dataJoined: DateTime.now(),
        worldPercentage: 0,
        contributionsCount: 0,
        userMoments: [],
        userCollections: [],
        userStamps: [],
      );

      // 4. Save to Global State (Provider)
      if (mounted) {
        // This makes the data available to all other screens instantly
        Provider.of<UserProvider>(context, listen: false).setUser(newUserData);

        // 5. Navigate to the next screen
        // Use the actual route name or the Widget itself
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const MapScreen()),
          (route) => false, // Clears the signup stack so they can't go back
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Setup Profile'),
        backgroundColor: Colors.deepPurple,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Add a profile picture",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              "Show people who you are!",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 40),

            // --- AVATAR PREVIEW ---
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: _imageFile != null ? FileImage(_imageFile!) : null,
                  child: _imageFile == null
                      ? Icon(Icons.person, size: 90, color: Colors.grey[400])
                      : null,
                ),
                if (_imageFile != null)
                  CircleAvatar(
                    backgroundColor: Colors.deepPurple,
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                      onPressed: () => setState(() => _imageFile = null),
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 40),

            // --- SELECTION BUTTONS ---
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _openCustomCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text("Camera"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepPurple,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickFromGallery,
                    icon: const Icon(Icons.photo),
                    label: const Text("Gallery"),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const Spacer(),

            // --- ACTIONS ---
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _completeSetup,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black87,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        _imageFile == null ? "Skip for now" : "Save & Continue",
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}