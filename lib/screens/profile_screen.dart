import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  // Basic structure of the profile screen with header, stats, collections, and photo grid
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F7), // Match the off-white background
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.edit_outlined, color: Colors.black)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: Colors.black)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const Padding(
              padding: EdgeInsets.only(left: 20, bottom: 10),
              child: Text("@travel_user", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            _buildCollectionsRow(),
            const SizedBox(height: 20),
            _buildTabSelector(),
            _buildPhotoGrid(),
          ],
        ),
      ),
    );
  }

  // Header with Stats and Profile Picture
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: () => _showProfileOptions(context), // Call the pop-up function
            child: const CircleAvatar(
              radius: 45,
              backgroundColor: Color(0xFF91A1E8),
              child: Text("t", style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w300)),
            ),
          ),
          _buildStatColumn("42", "spots"),
          _buildStatColumn("2.7K", "contributions"),
          _buildProgressCircle(),
        ],
      ),
    );
  }

  // Profile Picture Options Pop-up
  void _showProfileOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Constrains the box to its content
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    // The "larger" profile image
                    Container(
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(
                        color: Color(0xFF91A1E8),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text("t", style: TextStyle(fontSize: 80, color: Colors.white)),
                      ),
                    ),
                    // The Edit Pencil Button
                    // Corrected: Just Positioned, no "Position:" prefix
                  Positioned(
                    bottom: 5,
                    right: 5,
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context); 
                        _showPickerOptions(context); 
                      },
                      child: const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 20,
                        child: Icon(Icons.edit, color: Colors.blue, size: 20),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text("Profile Photo", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
          ),
        );
      },
    );
  }

  // Choosing/changing the profile picture (from Gallery, Camera, etc.)
  void _showPickerOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  // Logic for Gallery goes here
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  // Logic for Camera goes here
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // A collumn for the stats in the header
  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(count, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  // The world progress circle
  Widget _buildProgressCircle() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          height: 60,
          width: 60,
          child: CircularProgressIndicator(
            value: 0.24,
            strokeWidth: 6,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B444B)),
          ),
        ),
        const Column(
          children: [
            Text("24%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text("World", style: TextStyle(fontSize: 8, color: Colors.green)),
          ],
        )
      ],
    );
  }

  // Horizontal Collections Row
  Widget _buildCollectionsRow() {
    return SizedBox(
      height: 110,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
          _collectionCard("New\nCollection", Icons.add, null),
          _collectionCard("Japan trip\n2025", null, "https://picsum.photos/100/100?random=1"),
          _collectionCard("Family\nevents", null, "https://picsum.photos/100/100?random=2"),
          _collectionCard("Sunsets Around\nthe world", null, "https://picsum.photos/100/100?random=3"),
        ],
      ),
    );
  }

  Widget _collectionCard(String title, IconData? icon, String? imageUrl) {
    return Container(
      width: 90,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5)],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) Icon(icon, size: 30),
          if (imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(imageUrl, height: 50, width: 70, fit: BoxFit.cover),
            ),
          const SizedBox(height: 5),
          Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  // 3. Middle Tab Bar
  Widget _buildTabSelector() {
    return Container(
      color: Colors.grey[200],
      height: 50,
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Icon(Icons.blur_on),
          Icon(Icons.contact_mail_outlined),
          Icon(Icons.speed),
        ],
      ),
    );
  }

  // 4. Bottom Grid
  Widget _buildPhotoGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(border: Border.all(color: Colors.grey.withOpacity(0.2))),
        );
      },
    );
  }
}