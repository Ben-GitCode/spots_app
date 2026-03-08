import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'profile_screen.dart';

class Spot {  
  final String title;
  final String description;
  final LatLng location;
  final Color color;

  Spot(this.title, this.description, this.location, this.color);
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();

  final String mapTilerAPIKey = "fDMFRhQEG1PpzNvntybr";

  // Example dots (later from Supabase)
  final List<Spot> dots = [
    Spot(
      "Secret Garden",
      "A quiet place to read.",
      const LatLng(32.1782, 34.9076),
      Colors.green,
    ),
    Spot(
      "Urban Skate",
      "Best concrete ledges.",
      const LatLng(32.1795, 34.9051),
      Colors.orange,
    ),
    Spot(
      "Sunset Point",
      "Perfect view at 6pm.",
      const LatLng(32.1763, 34.9089),
      Colors.purple,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// MAP
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: LatLng(32.1782, 34.9076),
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all,
              ),
            ),
            children: [
              /// MAP TILES
              TileLayer(
                urlTemplate:
                    "https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$mapTilerAPIKey",
                userAgentPackageName: "com.example.spotsapp",
                retinaMode: true,
              ),

              /// DOT MARKERS
              MarkerLayer(
                markers: dots.map((spot) {
                  return Marker(
                    width: 50,
                    height: 50,
                    point: spot.location,
                    child: GestureDetector(
                      onTap: () =>
                          _showSpotInfo(spot), // Pass the specific spot data
                      child: _buildCustomMarker(spot.color),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          /// SAVED BUTTON (map corner)
          Positioned(
            top: 60,
            right: 16,
            child: FloatingActionButton(
              heroTag: "saved",
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _openSaved,
              child: const Icon(Icons.bookmark_border, color: Colors.black),
            ),
          ),

          /// BOTTOM TOOLBAR
          Positioned(bottom: 20, left: 20, right: 20, child: _buildToolbar()),
        ],
      ),
    );
  }

  // 3. CUSTOM MARKER DESIGN
  // A white circle with a colored center and a shadow
  Widget _buildCustomMarker(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(4), // White border thickness
      child: Container(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: const Icon(Icons.location_on, color: Colors.white, size: 24),
      ),
    );
  }

  Widget _buildToolbar() {
    return Stack(
      clipBehavior:
          Clip.none, // 1. Allows the button to overflow outside the container
      alignment: Alignment.center,
      children: [
        /// THE TOOLBAR BACKGROUND
        Container(
          height: 70,
          // 2. Makes the toolbar narrower horizontally
          margin: const EdgeInsets.symmetric(horizontal: 40),
          decoration: BoxDecoration(
            color: const Color.fromARGB(220, 55, 57, 77),
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
                icon: const Icon(Icons.route_outlined),
                color: Colors.white,
                iconSize: 35,
                onPressed: _openStepsSheet,
              ),

              /// INVISIBLE GAP
              /// Keeps space in the middle for the floating button
              const SizedBox(width: 60),

              IconButton(
                icon: const Icon(Icons.person_outline),
                color: Colors.white,
                iconSize: 35,
                onPressed: _openProfileScreen,
              ),
            ],
          ),
        ),

        /// THE FLOATING BIG PLUS
        Positioned(
          child: Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4), // Subtle outline
                width: 3,
              ),
              // 4. Gradient Color
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

  void _showSpotInfo(Spot spot) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent, // Allows rounded corners
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
          ),
          padding: const EdgeInsets.all(25),
          height: 250,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    spot.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Icon(Icons.star_border, color: spot.color, size: 30),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                spot.description,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: spot.color,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () => Navigator.pop(context), // Close popup
                  child: const Text("Navigate Here"),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // B. SLIDE FROM BOTTOM (The Left Button)
  void _openStepsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allows it to be taller than half screen
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        builder: (_, controller) => Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: ListView(
            controller: controller,
            children: const [
              Text(
                "Recent Activity",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ListTile(
                leading: Icon(Icons.directions_walk),
                title: Text("Walked 2km today"),
              ),
              ListTile(
                leading: Icon(Icons.map),
                title: Text("Discovered 'Urban Skate'"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // C. FULL SCREEN (The Right Button)
  void _openProfileScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ProfileScreen()),
    );
  }
}



/// CREATE MOMENT
void _createMoment() {
  print("Create moment");
}

void _openSaved() {
  print("Open saved");
}

void _openProfile() {
  print("Profile");
}

void _openSteps() {
  print("Steps / notifications");
}
