import 'package:flutter/material.dart';
import 'achievements_screen.dart';

class ProfileScreen extends StatelessWidget {
  final int worldPercentage;
  final int spotsCount;
  final int contributionsCount;
  final String username;
  final List<String> userPhotos;
  final ScrollController? scrollController;

  const ProfileScreen({
    super.key,
    required this.worldPercentage,
    required this.spotsCount,
    required this.contributionsCount,
    required this.username,
    required this.userPhotos,
    this.scrollController,
  });


  // Basic structure of the profile screen with header, stats, collections, and photo grid
  @override
Widget build(BuildContext context) {
  return Stack(
    clipBehavior: Clip.none,
    children: [
      // --- THE ACTUAL WHITE BOX ---
      Container(
        // Margin provides the "sky" for floating elements to sit in
        margin: const EdgeInsets.only(top: 45), 
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. HEADER AREA (Space for Name next to the floating photo)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // This empty space stays where the photo is floating
                  const SizedBox(width: 105), 
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 15, bottom: 10),
                      child: Text(
                        username,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF335C81),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. SPOTS & CONTRIBUTIONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatColumn("Spots", spotsCount),
                Container(width: 1, height: 30, color: Colors.grey[300]),
                _buildStatColumn("Contributions", contributionsCount),
              ],
            ),

            const SizedBox(height: 20),

            // 3. COLLECTIONS
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "Collections",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 100,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (context, index) {
                  return _buildCollectionCard(
                    "Trip ${index + 1}", 
                    userPhotos[index % userPhotos.length]
                  );
                },
              ),
            ),

            const Divider(height: 30, thickness: 1, indent: 20, endIndent: 20),

            // 4. SORT & FILTER
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Row(
                children: [
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.sort, size: 20, color: Colors.black87),
                    label: const Text("Sort", style: TextStyle(color: Colors.black87)),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list, size: 20, color: Colors.black87),
                    label: const Text("Filter", style: TextStyle(color: Colors.black87)),
                  ),
                ],
              ),
            ),

            const Divider(height: 10, thickness: 1),

            // 5. PHOTO GRID
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(10),
                // Ensure the grid scrolls within the sheet
                controller: scrollController, 
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: userPhotos.length,
                itemBuilder: (context, index) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(userPhotos[index], fit: BoxFit.cover),
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // --- FLOATING ELEMENTS (Placed last to be on top) ---

      // WORLD PERCENTAGE (Top Right)
      Positioned(
        top: 10, 
        right: 25,
        child: _buildCircularPercentage(worldPercentage.toDouble()),
      ),

      // PROFILE PHOTO (Top Left, Half-out)
      Positioned(
        top: 0, 
        left: 20,
        child: Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 4),
            image: DecorationImage(
              image: NetworkImage(userPhotos[0]),
              fit: BoxFit.cover,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 12,
                color: Colors.black.withOpacity(0.15),
                offset: const Offset(0, 4),
              )
            ],
          ),
        ),
      ),
    ],
  );
}

  // Header with Stats and Profile Picture
  // Widget _buildHeader(BuildContext context) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
  //     child: Row(
  //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
  //       children: [
  //         GestureDetector(
  //           onTap: () => _showProfileOptions(context), // Call the pop-up function
  //           child: const CircleAvatar(
  //             radius: 45,
  //             backgroundColor: Color(0xFF91A1E8),
  //             child: Text("t", style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.w300)),
  //           ),
  //         ),
  //         GestureDetector(
  //           onTap: () => _openAchievementsScreen(context), // New function for achievements
  //           child: Container(
  //             padding: const EdgeInsets.all(8),
  //             decoration: BoxDecoration(
  //               color: Colors.grey[200], // Subtle background for the "button"
  //               shape: BoxShape.circle,
  //             ),
  //           child: const Icon(Icons.import_contacts_sharp, size: 22, color: Colors.black87),
  //           ),
  //         ),
  //         _buildStatColumn("$spotsCount", "spots"),
  //         _buildStatColumn("$contributionsCount", "contributions"),
  //         _buildProgressCircle(),
  //       ],
  //     ),
  //   );
  // }

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
                        child: Icon(Icons.edit, color: Color(0xFF91A1E8)),
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
  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        if (count >= 1000000)
          Text(
            "${(((count / 1000000) * 10).floor()/10).toStringAsFixed(1)}M",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          )
        else if (count >= 1000)
          Text(
            "${(((count / 1000) * 10).floor()/10).toStringAsFixed(1)}K",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          )
        else
          Text(
            count.toString(),
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  } 
  
  Widget _buildCircularPercentage(double percent) {
    return Container(
      width: 70,
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFF335C81),
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      child: Center(
        child: Text(
          "$percent%",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
  // The world progress circle
  // Widget _buildProgressCircle() {
  //   return Stack(
  //     alignment: Alignment.center,
  //     children: [
  //       SizedBox(
  //         height: 60,
  //         width: 60,
  //         child: CircularProgressIndicator(
  //           value: worldPercentage / 100,
  //           strokeWidth: 6,
  //           backgroundColor: Colors.grey[300],
  //           valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF3B444B)),
  //         ),
  //       ),
  //       Column(
  //         children: [
  //           Text("$worldPercentage%", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  //           Text("World", style: TextStyle(fontSize: 10, color: Color(0xFF91A1E8))),
  //         ],
  //       )
  //     ],
  //   );
  // }
  Widget _buildCollectionCard(String title, String imageUrl) {
    return Container(
      width: 80,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              image: DecorationImage(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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

  // Building each collection card with an optional icon or image
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
    color: Color(0xFF91A1E8), // Darker grey background
    height: 45, // Slightly slimmer like the image
    width: double.infinity,
    // Row is removed to keep it empty
  );
}

  // 4. Bottom Grid
  Widget _buildPhotoGrid(List<String> photos) {
    return GridView.builder(
      shrinkWrap: true, // important
      physics: const NeverScrollableScrollPhysics(), // important
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color.fromARGB(255, 196, 201, 219),
            ),
          ),
          child: Image.network(
            photos[index],
            fit: BoxFit.cover,
          ),
        );
      },
    );
  }
  
  // Open the achievements screen
  void _openAchievementsScreen(context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AchievementsScreen()),
    );
  }
