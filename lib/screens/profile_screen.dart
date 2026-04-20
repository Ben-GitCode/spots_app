import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'achievements_screen.dart';
import 'package:provider/provider.dart';
import 'package:spots_app/providers/user_provider.dart';
import 'settings_screen.dart';
import '../utils/moment_data.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:spots_app/screens/moment_full_screen_view.dart'; // 🔹 Imported the full screen viewer!

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
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    // Wrap the existing UI in a FutureBuilder to fetch moments
    return FutureBuilder<List<Moment>>(
      future: Supabase.instance.client
          .from('moments')
          // 🔹 THE FIX: We explicitly tell it to follow the Author foreign key!
          .select('*, users!moments_user_id_fkey(username, profile_picture)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          // 🔹 THE NET: This physically forces the error into your console!
          .catchError((error) {
            print('\n==================================');
            print('🚨 CRITICAL SUPABASE ERROR:');
            print(error.toString());
            print('==================================\n');
            throw error; // Pass it down to the UI
          })
          .then((data) {
            try {
              final List<dynamic> listData = data as List<dynamic>;
              final moments = listData.map((m) => Moment.fromMap(m)).toList();
              print('✅ Successfully mapped ${moments.length} moments.');
              return moments;
            } catch (e) {
              print('⚠️ Mapping Error: $e');
              return [];
            }
          }),
      builder: (context, snapshot) {
        // 🔹 THE UI CATCHER: Shows the red error directly on your screen!
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                "Database Error:\n\n${snapshot.error}",
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final moments = snapshot.data ?? [];

        return Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 45),
              decoration: const BoxDecoration(
                color: Color(0xFFFBFBF2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 80,
                      height: 3,
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    Expanded(
                      child: CustomScrollView(
                        controller: scrollController,
                        slivers: [
                          SliverToBoxAdapter(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildNameHeader(user, context),
                                const SizedBox(height: 15),
                                _buildStatsAndPassport(context),
                                const SizedBox(height: 20),
                                _buildCollectionsSection(),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickyHeaderDelegate(
                              child: Container(
                                color: const Color(0xFFFBFBF2),
                                child: Column(
                                  children: [
                                    _buildSortFilterRow(),
                                    const Divider(
                                      height: 1,
                                      thickness: 1,
                                      indent: 20,
                                      endIndent: 20,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          // --- UPDATED PHOTO GRID ---
                          SliverPadding(
                            padding: const EdgeInsets.all(10),
                            sliver: moments.isEmpty
                                ? const SliverToBoxAdapter(
                                    child: Center(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 40.0),
                                        child: Text("No moments yet"),
                                      ),
                                    ),
                                  )
                                : SliverGrid(
                                    gridDelegate:
                                        const SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: 3,
                                          crossAxisSpacing: 10,
                                          mainAxisSpacing: 12,
                                          childAspectRatio: 0.75,
                                        ),
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final moment = moments[index];

                                      // 🔹 WRAPPED IN GESTURE DETECTOR TO OPEN FULL SCREEN
                                      return GestureDetector(
                                        onTap: () {
                                          HapticFeedback.lightImpact();
                                          Navigator.push(
                                            context,
                                            PageRouteBuilder(
                                              opaque: false,
                                              transitionDuration:
                                                  const Duration(
                                                    milliseconds: 350,
                                                  ),
                                              reverseTransitionDuration:
                                                  const Duration(
                                                    milliseconds: 300,
                                                  ),
                                              pageBuilder:
                                                  (
                                                    context,
                                                    animation,
                                                    secondaryAnimation,
                                                  ) => MomentFullScreenView(
                                                    moment: moment,
                                                  ),
                                              transitionsBuilder:
                                                  (
                                                    context,
                                                    animation,
                                                    secondaryAnimation,
                                                    child,
                                                  ) => FadeTransition(
                                                    opacity: animation,
                                                    child: child,
                                                  ),
                                            ),
                                          );
                                        },
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Colors.white,
                                            border: Border.all(
                                              color: Colors.black87,
                                              width: 2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(
                                                  0.1,
                                                ),
                                                blurRadius: 6,
                                                offset: const Offset(2, 4),
                                              ),
                                            ],
                                          ),
                                          padding: const EdgeInsets.all(6),
                                          child: Column(
                                            children: [
                                              // --- MEDIA CONTENT AREA ---
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(2),
                                                  // 🔹 CLEANED UP: Now uses the polymorphic architecture directly!
                                                  child: Stack(
                                                    fit: StackFit.expand,
                                                    children: [
                                                      moment.media.buildPreview(
                                                        context,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),

                                              const SizedBox(height: 12),

                                              // --- THE CHIN (Caption) ---
                                              Text(
                                                moment.caption,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontSize: 8,
                                                  color: Colors.black54,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }, childCount: moments.length),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Floating Profile Photo
            Positioned(
              top: 10,
              left: 20,
              child: GestureDetector(
                onTap: () => _showProfileOptions(context, user),
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black87, width: 3),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: NetworkImage(user.profilePictureUrl),
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 12,
                        color: Colors.black.withOpacity(0.15),
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // The header with the username, aligned to the right of the profile photo
  Widget _buildNameHeader(final user, BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const SizedBox(width: 105), // Space for the floating photo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 10),
              child: Text(
                user.username,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF335C81),
                ),
              ),
            ),
          ),
          // Edit Pencil Icon
          IconButton(
            icon: const Icon(Icons.edit, size: 20),
            color: Colors.black87,
            onPressed: () {
              // TODO: Navigate to Edit Profile
            },
          ),
          // Settings Gear Icon
          IconButton(
            icon: const Icon(Icons.settings, size: 20),
            color: Colors.black87,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // The row with Moments, Contributions, and the Passport icon
  Widget _buildStatsAndPassport(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          _buildStatColumn("Moments", spotsCount),
          const SizedBox(width: 20),
          Container(width: 1, height: 30, color: Colors.grey[300]),
          const SizedBox(width: 20),
          _buildStatColumn("Contributions", contributionsCount),

          const SizedBox(width: 20),

          IconButton(
            icon: const Icon(Icons.badge, size: 28),
            onPressed: () => _openAchievementsScreen(context),
            tooltip: 'Open Achievements',
            color: Colors.black87,
          ),

          const SizedBox(width: 10),

          // Floating World Percentage Circle
          Positioned(
            child: _buildCircularPercentage(worldPercentage.toDouble()),
          ),
        ],
      ),
    );
  }

  // Profile Picture Options Pop-up
  void _showProfileOptions(BuildContext context, user) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    Container(
                      width: 150,
                      height: 150,
                      decoration: const BoxDecoration(
                        color: Color(0xFF91A1E8),
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: Image.network(
                          user.profilePictureUrl,
                          fit: BoxFit.cover,
                          // This handles the loading state
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            );
                          },
                          // In case of a 404 or no internet, show the "t"
                          errorBuilder: (context, error, stackTrace) {
                            return const Center(
                              child: Text(
                                "t",
                                style: TextStyle(
                                  fontSize: 80,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
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
                const Text(
                  "Profile Photo",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
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

  // The horizontal list of collections (Trips, Guides, etc.) with the "New Collection" box at the start
  Widget _buildCollectionsSection() {
    return SizedBox(
      height: 125,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        scrollDirection: Axis.horizontal,
        // Increase count by 1 to make room for the "New Collection" box
        itemCount: 6,
        itemBuilder: (context, index) {
          if (index == 0) {
            // The first item: Empty box with a plus sign
            return _buildCollectionCard("New Collection", "add_button");
          } // Subtract 1 from index for the actual data
          int tripIndex = index - 1;
          return _buildCollectionCard(
            "Collection ${tripIndex + 1}",
            userPhotos[tripIndex % userPhotos.length],
          );
        },
      ),
    );
  }

  // A single card in the collections row, which can either be a collection or the "New Collection" button
  Widget _buildCollectionCard(String title, String imageUrl) {
    final bool isAddButton = imageUrl == "add_button";
    const Color polaroidBorderColor = Color(0xFFC7CDCF);

    return Container(
      width: 100, // Reduced from 140
      margin: const EdgeInsets.only(right: 12, top: 10, bottom: 5),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // --- THE LAYERS (Background) ---
          for (int i = 0; i < 2; i++)
            Positioned(
              child: Transform.rotate(
                angle: (i == 0) ? 0.3 : 0.1,
                child: Container(
                  width: 100, // Scaled down
                  height: 100,
                  decoration: BoxDecoration(
                    color: (i == 0)
                        ? const Color.fromARGB(31, 122, 118, 118)
                        : const Color.fromARGB(255, 200, 204, 204),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),

          // --- THE POLAROID (Main Content) ---
          Container(
            width: 90, // Reduced width
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: polaroidBorderColor, width: 1.5),
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Photo Frame
                Padding(
                  padding: const EdgeInsets.all(5.0), // Tighter padding
                  child: Container(
                    height: 65, // Much smaller photo height
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: isAddButton
                          ? const Center(
                              child: Icon(
                                Icons.add,
                                color: Colors.black45,
                                size: 30,
                              ),
                            )
                          : Image.network(imageUrl, fit: BoxFit.cover),
                    ),
                  ),
                ),

                // Title text
                Padding(
                  padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4),
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10, // Smaller font
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- THE PAPERCLIP (Scaled down) ---
          Positioned(
            top: -5,
            right: -8,
            child: Transform.rotate(
              angle:
                  0.6, // Tweak this number to change the tilt (try 0.4 to 0.8)
              child: Icon(
                Icons.attach_file,
                size: 40, // Reduced from 45
                color: Colors.black.withOpacity(0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // The horizontal row with the Sort and Filter buttons, which becomes sticky when scrolling
  Widget _buildSortFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          const SizedBox(
            width: 100,
          ), // Keeps alignment consistent with the name above
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.sort, size: 20, color: Colors.black87),
            label: const Text("Sort", style: TextStyle(color: Colors.black87)),
          ),
          const SizedBox(width: 20),
          Container(width: 1, height: 30, color: Colors.grey[300]),
          const SizedBox(width: 20),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(
              Icons.filter_list,
              size: 20,
              color: Colors.black87,
            ),
            label: const Text(
              "Filter",
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  // Buuilds the numbers for Moments and Contributions, converting large numbers to K/M format
  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        if (count >= 1000000)
          Text(
            "${(((count / 1000000) * 10).floor() / 10).toStringAsFixed(1)}M",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          )
        else if (count >= 1000)
          Text(
            "${(((count / 1000) * 10).floor() / 10).toStringAsFixed(1)}K",
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

  // The world progress circle
  Widget _buildCircularPercentage(double percent) {
    // Normalize percent to a value between 0.0 and 1.0 for the progress indicator
    double progressValue = percent / 100;

    return Container(
      width: 60, // Slightly larger to breathe
      height: 60,
      decoration: const BoxDecoration(
        color: Color(0xFF374146), // Dark slate from your image
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black26)],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The Progress Arc
          SizedBox(
            width:
                70, // Slightly smaller than container to create a "border" effect
            height: 70,
            child: CircularProgressIndicator(
              value: progressValue,
              strokeWidth: 8, // Adjust thickness to match image
              backgroundColor: Colors.transparent, // Background of the track
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFC5D9B0), // The light green from your image
              ),
              strokeCap: StrokeCap.butt, // Square edges for the progress line
            ),
          ),
          // The Text Column
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "${percent.toInt()}%",
                style: const TextStyle(
                  color: Color(0xFFC5D9B0), // Matching the green
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                ),
              ),
              const Text(
                "World",
                style: TextStyle(color: Color(0xFFC5D9B0), fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Open the achievements screen
  void _openAchievementsScreen(context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AchievementsScreen()),
    );
  }
}

// Custom SliverPersistentHeaderDelegate for the sticky Sort & Filter bar that stays when scrolled up
class _StickyHeaderDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;
  _StickyHeaderDelegate({required this.child});

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return child;
  }

  @override
  double get maxExtent => 60.0; // Adjust based on your Sort/Filter height
  @override
  double get minExtent => 60.0;

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      false;
}
