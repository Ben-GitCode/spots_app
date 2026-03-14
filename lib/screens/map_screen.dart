import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'profile_screen.dart';
import 'package:spots_app/utils/models.dart';
import 'spot_details_screen.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'traces_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});
  

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final String mapTilerAPIKey = "fDMFRhQEG1PpzNvntybr";
  bool _profileOpen = false;

  Spot? _selectedSpot;
  bool _isMoving = false;

  // DUMMY DATA
  final List<Spot> spots = [
    Spot(
      id: '1',
      ownerId: 'user_123',
      title: "Secret Garden",
      description: "A quiet place.",
      location: const LatLng(32.1782, 34.9076),
      type: SpotTypes.public,
      reactionCounts: {SpotReactions.wholesome: 55, SpotReactions.support: 2},
    ),
    Spot(
      id: '2',
      ownerId: 'user_me',
      title: "My Hidden Base",
      description: "Only for me.",
      location: const LatLng(32.1795, 34.9051),
      type: SpotTypes.me,
      reactionCounts: {SpotReactions.meh: 10, SpotReactions.wow: 5},
    ),
    Spot(
      id: '3',
      ownerId: 'user_456',
      title: "Skate Park",
      description: "Concrete ledges.",
      location: const LatLng(32.1763, 34.9089),
      type: SpotTypes.private,
      reactionCounts: {
        SpotReactions.support: 30,
        SpotReactions.wholesome: 12,
        SpotReactions.insightful: 40,
      },
    ),
  ];

  void _onSpotTap(Spot spot) {
    setState(() {
      _selectedSpot = spot;
      _isMoving = true;
    });
    _animatedMapMove(spot.location, 16.0);
  }

  void _onMapTap() {
    if (_profileOpen) {
      Navigator.pop(context);
      return;
    }
    if (_selectedSpot != null) {
      setState(() {
        _selectedSpot = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 1. MAP LAYER
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(32.1782, 34.9076),
              initialZoom: 15,
              onTap: (_, _) => _onMapTap(),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$mapTilerAPIKey",
                userAgentPackageName: "com.example.spotsapp",
                retinaMode: true,
              ),

              /// LAYER 1: THE DOTS / PINS
              MarkerLayer(
                markers: spots.map((spot) {
                  final isSelected = _selectedSpot?.id == spot.id;

                  return Marker(
                    width: isSelected ? 60 : 45,
                    height: isSelected ? 60 : 45,
                    point: spot.location,
                    rotate: true,
                    alignment: Alignment.topCenter,
                    key: ValueKey(spot.id),
                    child: GestureDetector(
                      onTap: () => _onSpotTap(spot),
                      child: isSelected
                          ? _buildSelectedPin()
                          : _buildStandardSpot(spot),
                    ),
                  );
                }).toList(),
              ),

              /// LAYER 2: THE POPUP (ANCHORED TO MAP)
              /// Only render if a spot is selected and we stopped moving
              if (_selectedSpot != null && !_isMoving)
                MarkerLayer(
                  markers: [
                    Marker(
                      rotate: true,
                      point: _selectedSpot!.location,
                      width: 250,
                      height: 275, // Height of your popup
                      // 🔹 ANCHORING MAGIC:
                      // Alignment.bottomCenter means the bottom of this marker touches the LatLng.
                      // This makes it "sit" on top of the point.
                      alignment: Alignment.topCenter,
                      child: Padding(
                        // Add padding at the bottom so it doesn't cover the Pin itself
                        padding: const EdgeInsets.only(bottom: 65),
                        child: _buildPopup(_selectedSpot!),
                      ),
                    ),
                  ],
                ),
            ],
          ),

          // 2. THE FLOATING STACK (BOTTOM RIGHT)
          Positioned(
            right: 15,
            bottom: 120,
            child: Column(
              children: [
                // BOOKMARKS BUTTON
                FloatingActionButton(
                  heroTag: "saved",
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  backgroundColor: Color.fromARGB(255, 55, 57, 77),
                  elevation: 4,
                  onPressed: _openSaved,
                  child: const Icon(Icons.bookmark_border, color: Colors.white),
                ),

                const SizedBox(height: 15),

                // LOCATION BUTTON
                FloatingActionButton(
                  heroTag: "location",
                  shape: const CircleBorder(),
                  backgroundColor: Colors.white,
                  elevation: 4,
                  onPressed: () {},
                  child: const Icon(Icons.my_location, color: Colors.black),
                ),
              ],
            ),
          ),

          /// 4. BOTTOM TOOLBAR
          Positioned(bottom: 20, left: 0, right: 0, child: _buildToolbar()),
        ],
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildPopup(Spot spot) {
    // 1. CALCULATE TOP 3 REACTIONS
    // Sort the reaction map by count (highest first)
    final sortedEntries = spot.reactionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Take up to 3 of the most popular reactions
    final topReactions = sortedEntries.take(3).map((e) => e.key).toList();

    // Calculate total interactions for the "people count" number
    final totalReactions = spot.reactionCounts.values.fold(
      0,
      (sum, count) => sum + count,
    );

    // 2. PROXIMITY LOGIC (Near vs Far)
    // // MOCK USER LOCATION (Imagine the user is standing in Tel Aviv)
    // // Later, you will get this from the geolocator package!
    // final myCurrentLocation = const LatLng(32.1780, 34.9070);

    // // Calculate distance in meters using latlong2
    // const Distance distanceCalculator = Distance();
    // final double distanceInMeters = distanceCalculator.as(
    //   LengthUnit.Meter,
    //   myCurrentLocation,
    //   spot.location,
    // );

    // // If they are within 100 meters, unlock the preview!
    // bool isNear = distanceInMeters <= 100;
    bool isNear = false;

    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 240,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(
            0xFFF8F7F2,
          ), // Creamy background matching your image
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              blurRadius: 15,
              color: Colors.black.withOpacity(0.2),
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min, // Wraps content tightly
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- HEADER: Title & Bookmark ---
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        spot.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF335C81), // Dark blue text
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Created 3 Months Ago",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.bookmark_border,
                  color: Colors.black87,
                  size: 28,
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- MIDDLE: Overlapping Emojis & People Count ---
            Row(
              children: [
                // Overlapping Emojis Stack
                if (topReactions.isNotEmpty)
                  SizedBox(
                    // Dynamically size width based on how many emojis we have (up to 3)
                    width: 32.0 + ((topReactions.length - 1) * 20.0),
                    height: 32,
                    child: Stack(
                      children: List.generate(topReactions.length, (index) {
                        return Positioned(
                          left:
                              index *
                              20.0, // Shift each emoji 20px to the right
                          child: Container(
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(
                                0xFFF8F7F2,
                              ), // Matches bg to prevent transparency bleed
                            ),
                            child: Text(
                              spot.getEmojiForReaction(topReactions[index]),
                              style: const TextStyle(fontSize: 26),
                            ),
                          ),
                        );
                      }),
                    ),
                  )
                else
                  const Text(
                    "No reactions yet",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                const Spacer(),

                // People Group Icon & Total
                const Icon(Icons.group, size: 28, color: Colors.black87),
                const SizedBox(width: 6),
                Text(
                  totalReactions.toString(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF335C81), // Dark blue
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // --- BOTTOM: The Dynamic "Preview" Box ---
            if (isNear)
              // STATE 1: NEAR (Clickable Button)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SpotDetailsScreen(spot: spot),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.black, // Or use a vibrant "active" color
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "Preview Spot",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              )
            else
              // STATE 2: FAR AWAY (Locked State)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Text(
                      "Preview Not Available",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Go Near Spot To View",
                      style: TextStyle(
                        color: Color(0xFF81D4FA),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ), // Light blue text
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectedPin() {
    return const Icon(
      Icons.location_on,
      color: Colors.red,
      size: 55,
      shadows: [
        Shadow(blurRadius: 10, color: Colors.black45, offset: Offset(0, 5)),
      ],
    );
  }

  Widget _buildStandardSpot(Spot spot) {
    return Container(
      decoration: BoxDecoration(
        color: spot.innerColor,
        shape: BoxShape.circle,
        border: Border.all(color: spot.outlineColor, width: 5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Center(
        child: Text(spot.topEmoji, style: const TextStyle(fontSize: 20)),
      ),
    );
  }

  Widget _buildToolbar() {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          height: 70,
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 55, 57, 77),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                blurRadius: 20,
                color: Colors.black.withValues(alpha: 0.5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              IconButton(
                icon: SvgPicture.asset(
                  'assets/icons/FootPrint.svg',
                  height: 35,
                  width: 35,
                ),
                onPressed: _openStepsSheet,
              ),
              const SizedBox(width: 60),
              IconButton(
                icon: const Icon(Icons.person_outline),
                color: Colors.white,
                iconSize: 40,
                onPressed: _openProfileScreen,
              ),
            ],
          ),
        ),
        Positioned(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 3,
              ),
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF91C5F2),
                  Color(0xFFF2A7E6),
                  Color(0xEEEEEEFF),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.deepPurple.withValues(alpha: 0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.add, color: Colors.white, size: 70),
              onPressed: _createMoment,
            ),
          ),
        ),
      ],
    );
  }

  // --- ACTIONS ---

  void _openStepsSheet() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const TracesScreen()),
    );
  }
    
  void _openProfileScreen() {
    _profileOpen = true;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      barrierColor: Colors.transparent, 
      backgroundColor: Colors.transparent,
      clipBehavior: Clip.none,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75, // 0.85
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(25),
              ),
              child: ProfileScreen(
                worldPercentage: 24,
                spotsCount: 3567788,
                contributionsCount: 12365,
                username: "@travel_user",
                scrollController: scrollController,
                userPhotos: [
                  "https://th.bing.com/th/id/OIP.WX9eEoyCf79l0nvM9TdlkgAAAA?w=143&h=180&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                  "https://th.bing.com/th/id/OIP.qNNbhflJ7crF62b0IqTBZQHaEK?w=328&h=185&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
            
                ],
              ),
            );
          },
        );
      },
    ).whenComplete(() {
    _profileOpen = false;
  });
}


  // Moved these INSIDE the class where they belong!
  void _createMoment() {
    print("Create moment");
  }

  void _openSaved() {
    print("Open saved");
  }

  void _onSaveSpot(Spot spot) {}

  /// SMOOTH MOVE ANIMATION
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // Create some tweens. These serve to split up the transition from one location to another.
    // In our case, we want to split the degrees of lat/lng so that we can get a smooth path from A to B.
    final latTween = Tween<double>(
      begin: _mapController.camera.center.latitude,
      end: destLocation.latitude,
    );
    final lngTween = Tween<double>(
      begin: _mapController.camera.center.longitude,
      end: destLocation.longitude,
    );
    final zoomTween = Tween<double>(
      begin: _mapController.camera.zoom,
      end: destZoom,
    );

    // Create a controller that will play the animation over 500ms
    final controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // The animation curve (EaseInOut is smooth start/end)
    final Animation<double> animation = CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    );

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
        // 🔹 CRITICAL: Tell the app the move is done so the popup appears!
        setState(() {
          _isMoving = false;
        });
      }
    });

    controller.forward();
  }
}
