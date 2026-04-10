import 'package:flutter/material.dart';

import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:map_launcher/map_launcher.dart';
import 'package:flutter_map_cache/flutter_map_cache.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio_cache_interceptor_file_store/dio_cache_interceptor_file_store.dart';
import 'package:spots_app/screens/spot_display_screen.dart';
import 'package:spots_app/components/overlapping_reaction_stack.dart';
import 'dart:io';
import 'dart:async';

import 'profile_screen.dart';
import 'create_moment_screen.dart';
import 'package:spots_app/utils/models.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'traces_screen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'profile_scrapbook.dart';

import 'edge_function_test_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  final MapController _mapController = MapController();
  final String mapTilerAPIKey = dotenv.env['MAPTILER_KEY']!;
  bool _profileOpen = false;

  // 🔹 Streams to control the "Lock-on" behavior
  late AlignOnUpdate _alignPositionOnUpdate;
  late final StreamController<double?> _alignPositionStreamController;

  bool _hasPermissions = false;

  // Future for the cache store to ensure it's ready before the map builds
  late Future<Directory> _cacheDir;

  // 🔹 1. NEW VARIABLES FOR PROXIMITY MATH
  LatLng? _currentLocation;
  StreamSubscription<Position>? _positionStreamSubscription;

  @override
  void initState() {
    super.initState();
    _cacheDir = getTemporaryDirectory(); // Get a place to store tiles

    // 🔹 Initialize location tracking streams
    _alignPositionOnUpdate = AlignOnUpdate.always; // Start locked on
    _alignPositionStreamController = StreamController<double?>();
    _checkLocationPermissions();
  }

  @override
  void dispose() {
    _positionStreamSubscription?.cancel();
    _alignPositionStreamController.close();
    _mapController.dispose();
    super.dispose();
  }

  // 🔹 Permission Check Logic
  Future<void> _checkLocationPermissions() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _showErrorSnackBar("Please enable location services.");
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) {
      _showPreciseLocationDialog(
        "Location permissions are permanently denied. We need them to show your Spots.",
      );
      return;
    }

    // 🔹 THE HARD GATE: Check for Precise vs Approximate
    final accuracy = await Geolocator.getLocationAccuracy();

    if (accuracy == LocationAccuracyStatus.reduced) {
      // The user chose "Approximate". We halt everything and force them to Settings.
      _showPreciseLocationDialog(
        "Spots relies on your exact location to physically unlock nearby areas. Please open Settings and toggle 'Precise Location' to ON.",
      );
      return; // ⛔️ HALT: Do not set _hasPermissions to true
    }

    // If we made it here, they gave us standard, permanent Precise Location!
    setState(() {
      _hasPermissions = true;
    });

    _startLocationTracking();
  }

  // 🔹 Call this at the very end of your _checkLocationPermissions() method!
  void _startLocationTracking() {
    // Only update the stream if the user moves at least 3 meters
    // (Saves massive amounts of battery compared to continuous updates)
    const LocationSettings locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best, // We already forced precise!
      distanceFilter: 3,
    );

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: locationSettings,
        ).listen((Position? position) {
          if (position != null && mounted) {
            setState(() {
              _currentLocation = LatLng(position.latitude, position.longitude);
            });
          }
        });
  }

  // 🔹 The UX prompt that routes them to the iOS/Android Settings app
  void _showPreciseLocationDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false, // Force them to interact with the dialog
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: const Color(0xFF1E1E2A),
          title: const Text(
            "Precise Location Required",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: Text(
            message,
            style: const TextStyle(color: Colors.white70, height: 1.4),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(context), // Let them cancel and stay locked out
              child: const Text(
                "Cancel",
                style: TextStyle(color: Colors.white54),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () async {
                Navigator.pop(context);
                // 🔹 This magic line opens the OS Settings exactly on your App's page
                await Geolocator.openAppSettings();
              },
              child: const Text(
                "Open Settings",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // 🔹 The Target Button Action
  void _lockOnUser() {
    setState(() {
      _alignPositionOnUpdate = AlignOnUpdate.always;
    });
    // Snap the camera back to the user at zoom level 16.0
    _alignPositionStreamController.add(16.0);
  }

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
    Spot(
      id: '4',
      ownerId: 'user_4',
      title: "Far Far Away",
      description: "km test",
      location: const LatLng(32.1763, 34.9589),
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
      _alignPositionOnUpdate = AlignOnUpdate.never;
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
      body: FutureBuilder<Directory>(
        future: _cacheDir,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
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
                  // 🔹 Break the lock if the user physically drags the map
                  onPositionChanged: (MapPosition position, bool hasGesture) {
                    if (hasGesture &&
                        _alignPositionOnUpdate == AlignOnUpdate.always) {
                      setState(() {
                        _alignPositionOnUpdate = AlignOnUpdate.never;
                      });
                    }
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: "com.example.spotsapp",
                    retinaMode: false,
                    tileDisplay: const TileDisplay.fadeIn(
                      duration: Duration(milliseconds: 300),
                    ),
                  ),

                  // 🔹 The Magic Location Marker Layer
                  if (_hasPermissions)
                    CurrentLocationLayer(
                      alignPositionStream:
                          _alignPositionStreamController.stream,
                      alignPositionOnUpdate: _alignPositionOnUpdate,
                      style: LocationMarkerStyle(
                        marker: const DefaultLocationMarker(
                          color: Colors.blueAccent,
                        ),
                        markerSize: const Size(24, 24),
                        showHeadingSector:
                            true, // 🔹 Enables the rotation compass
                        headingSectorColor: Colors.blueAccent.withOpacity(0.3),
                        headingSectorRadius: 60,
                      ),
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
                        // alignment: isSelected
                        //     ? Alignment.center
                        //     : Alignment.center,
                        // alignment: Alignment.topCenter,
                        alignment: Alignment.center,
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
                  if (_selectedSpot != null && !_isMoving)
                    MarkerLayer(
                      markers: [
                        Marker(
                          rotate: true,
                          point: _selectedSpot!.location,
                          width: 250,
                          height: 245,
                          alignment: Alignment.topCenter,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 30),
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
                    FloatingActionButton(
                      heroTag: "saved",
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      backgroundColor: const Color.fromARGB(255, 55, 57, 77),
                      elevation: 4,
                      onPressed: _openSaved,
                      child: const Icon(
                        Icons.bookmark_border,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 15),
                    // 🔹 Updated Target Button
                    FloatingActionButton(
                      heroTag: "location",
                      shape: const CircleBorder(),
                      backgroundColor: Colors.white,
                      elevation: 4,
                      onPressed: _hasPermissions
                          ? _lockOnUser
                          : _checkLocationPermissions,
                      child: Icon(
                        _alignPositionOnUpdate == AlignOnUpdate.always
                            ? Icons.my_location_rounded
                            : Icons.location_searching_rounded,
                        color: _alignPositionOnUpdate == AlignOnUpdate.always
                            ? Colors.blueAccent
                            : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              /// 4. BOTTOM TOOLBAR
              Positioned(bottom: 20, left: 0, right: 0, child: _buildToolbar()),
            ],
          );
        },
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

    // 🔹 2. THE LOCAL PROXIMITY MATH
    bool isNear = false;
    double? distanceInMeters;

    if (_currentLocation != null) {
      // The Distance() class uses the Haversine formula to account for the curvature of the Earth
      const Distance distanceCalculator = Distance();

      distanceInMeters = distanceCalculator.as(
        LengthUnit.Meter,
        _currentLocation!,
        spot.location,
      );

      // Unlock threshold: 10 meters
      isNear = distanceInMeters <= 10;
    }

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
                  OverlappingReactionStack(
                    reactions: topReactions,
                    totalReactions: totalReactions,
                    outlineColor: Color(0xFFF8F7F2),
                    counterTextColor: Colors.black87,
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

            const SizedBox(height: 15),

            // --- BOTTOM: The Dynamic "Preview" Box ---
            if (isNear)
              // STATE 1: NEAR (Clickable Button)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SpotDisplayScreen(spotTitle: spot.title),
                    ),
                  );
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 25),
                  decoration: BoxDecoration(
                    color: Color.fromARGB(255, 134, 166, 65),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Center(
                    child: Text(
                      "Preview Spot",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              )
            else
              // STATE 2: FAR AWAY (Navigation State)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Go Near spot To View",
                    style: TextStyle(
                      color: Color(0xFF335C81), // Matched your dark blue header
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _openNavigationSheet(spot),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.blueAccent,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.blueAccent.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDistance(distanceInMeters),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          const Icon(
                            Icons.directions, // Cool navigation arrow
                            color: Colors.white,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  // 🔹 Formats distance: meters if under 1km, kilometers if over
  String _formatDistance(double? meters) {
    if (meters == null) return "Locating...";

    if (meters < 1000) {
      return "${meters.ceil()}m away";
    } else {
      // Divides by 1000 and shows 1 decimal place (e.g., 1.2km)
      return "${(meters / 1000).toStringAsFixed(1)}km away";
    }
  }

  // 🔹 Opens the Navigation Bottom Sheet
  void _openNavigationSheet(Spot spot) async {
    try {
      final availableMaps = await MapLauncher.installedMaps;

      // 🔹 1. Check if the widget is still alive after the async call
      if (!mounted) return;

      // 🔹 2. Handle the edge case where NO maps are installed
      if (availableMaps.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("No navigation apps found on this device."),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return; // Halt execution here
      }

      // 🔹 3. Show the bottom sheet if maps exist
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (BuildContext context) {
          return SafeArea(
            child: SingleChildScrollView(
              child: Wrap(
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text(
                      "Navigate to Spot",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  for (var map in availableMaps)
                    ListTile(
                      onTap: () {
                        // 🔹 4. Close the bottom sheet FIRST
                        Navigator.pop(context);

                        // Then launch the external map app
                        map.showMarker(
                          coords: Coords(
                            spot.location.latitude,
                            spot.location.longitude,
                          ),
                          title: spot.title,
                        );
                      },
                      title: Text(map.mapName),
                      leading: SvgPicture.asset(
                        map.icon,
                        height: 30.0,
                        width: 30.0,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      debugPrint("Navigation Error: $e");
    }
  }

  // Widget _buildSelectedPin() {
  //   return const Icon(
  //     Icons.location_on,
  //     color: Colors.red,
  //     size: 55,
  //     shadows: [
  //       Shadow(blurRadius: 10, color: Colors.black45, offset: Offset(0, 5)),
  //     ],
  //   );
  // }
  Widget _buildSelectedPin() {
    return Transform.translate(
      // 🔹 Tweak these X and Y values until the needle is perfectly locked onto the spot!
      // Negative Y moves it UP. Negative X moves it LEFT.
      offset: const Offset(-11, 7),
      child: SvgPicture.asset(
        'assets/icons/PushPin.svg',
        width: 55,
        height: 55,
      ),
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
        child: Image.asset(spot.topReactionAsset, width: 25, height: 25),
        // child: Text(spot.topEmoji, style: const TextStyle(fontSize: 20)),
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
              onPressed: _openCreateMomentScreen,
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
          minChildSize: 0.75,
          maxChildSize: 0.75,
          expand: false,
          builder: (context, scrollController) {
            return ProfileScreen(
              worldPercentage: 33,
              spotsCount: 3567788,
              contributionsCount: 12365,
              username: "@travel_user",
              scrollController: scrollController,
              userPhotos: [
                "https://th.bing.com/th/id/OIP.Ufv8ve9S5hVyGsMqbNwqEAHaE8?w=301&h=180&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
                "https://th.bing.com/th/id/OIP.evi8jxbBP9Xd_hPbwyEoVAHaE8?w=245&h=180&c=7&r=0&o=7&dpr=2&pid=1.7&rm=3",
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      _profileOpen = false;
    });
  }

  void _openSupabaseTestScreen() {
    Navigator.push(
      context,
      // 🔹 CHANGE THIS LINE to use the new screen you just created
      MaterialPageRoute(builder: (context) => EdgeFunctionTestScreen()),
    );
  }

  void _openCreateMomentScreen() {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false, // 🔹 THIS IS CRITICAL for the blur effect to work!
        pageBuilder: (context, animation, secondaryAnimation) {
          return const CreateMomentScreen();
        },
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutCubic;

          var tween = Tween(
            begin: begin,
            end: end,
          ).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(position: offsetAnimation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
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
      curve: Curves.easeInOutCubic,
    );

    controller.addListener(() {
      // Only move if the controller is still active to prevent
      // trying to move after a dispose() call
      if (mounted) {
        _mapController.move(
          LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
          zoomTween.evaluate(animation),
        );
      }
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
