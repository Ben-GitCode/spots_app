import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // 🔹 Required for distance calculation

// --- DATA MODELS ---
enum MomentType { photo, text, audio, map }

class Moment {
  final MomentType type;
  final String title;
  final String date;
  final String? content;
  final LatLng location; // 🔹 Added geographic location
  final double rotation;

  Moment({
    required this.type,
    required this.title,
    required this.date,
    required this.location,
    this.content,
  }) : rotation = (Random().nextDouble() - 0.5) * 0.08;
}

class ProfileScrapbookScreen extends StatelessWidget {
  ProfileScrapbookScreen({super.key});

  final String mapTilerAPIKey = "fDMFRhQEG1PpzNvntybr";

  // 🔹 MOCK USER LOCATION (Imagine they are standing near Tel Aviv)
  final LatLng currentUserLocation = const LatLng(32.1624, 34.8447);

  // DUMMY DATA: Now includes coordinates for the Map and Distance calculation
  final List<Moment> moments = [
    Moment(
      type: MomentType.photo,
      title: "Neon Alley",
      date: "Oct 12",
      location: const LatLng(35.6895, 139.6917), // Tokyo (Far Away)
      content: "https://picsum.photos/400/500",
    ),
    Moment(
      type: MomentType.text,
      title: "Late night thoughts",
      date: "Oct 10",
      location: const LatLng(32.0853, 34.7818), // Tel Aviv
      content:
          "Just realized the best pizza is the one you eat at 2 AM on the sidewalk.",
    ),
    Moment(
      type: MomentType.map,
      title: "Hidden Gem Coffee",
      date: "Oct 5",
      location: const LatLng(32.1782, 34.9076), // Secret Garden coordinates
      content: "Downtown District",
    ),
    Moment(
      type: MomentType.audio,
      title: "Street Musician",
      date: "Sep 28",
      location: const LatLng(
        32.1620,
        34.8450,
      ), // Very close to current location
      content: "1:15",
    ),
    Moment(
      type: MomentType.photo,
      title: "Skate Park vibes",
      date: "Sep 20",
      location: const LatLng(32.1763, 34.9089),
      content: "https://picsum.photos/400/300",
    ),
  ];

  // 🔹 DISTANCE CALCULATOR HELPER
  String _getFormattedDistance(LatLng spotLocation) {
    const Distance distanceCalculator = Distance();
    final double distanceInMeters = distanceCalculator.as(
      LengthUnit.Meter,
      currentUserLocation,
      spotLocation,
    );

    if (distanceInMeters < 1000) {
      return "${distanceInMeters.toInt()}m away";
    } else {
      final double distanceInKm = distanceInMeters / 1000;
      if (distanceInKm > 100) {
        return "${distanceInKm.toInt()}km away"; // No decimals for huge distances
      }
      return "${distanceInKm.toStringAsFixed(1)}km away";
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> leftColumn = [];
    List<Widget> rightColumn = [];

    for (int i = 0; i < moments.length; i++) {
      Widget card = _buildCard(moments[i]);
      if (i.isEven) {
        leftColumn.add(card);
      } else {
        rightColumn.add(card);
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF2), // Creamy Scrapbook Page
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBFBF2),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My Traces",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 10),

            // THE MASONRY GRID
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Column(children: leftColumn)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      // Push the right column down slightly for a staggered look
                      children: [const SizedBox(height: 40), ...rightColumn],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- HEADER: MAP COVER PHOTO & AVATAR ---
  Widget _buildHeader() {
    return Column(
      children: [
        // 1. THE MAP COVER PHOTO
        SizedBox(
          height: 200,
          width: double.infinity,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: const LatLng(
                32.1700,
                34.8500,
              ), // Center of the dummy data
              initialZoom: 10.5,
              // 🔹 Disable interactions so user can scroll down the profile without getting stuck on the map
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=$mapTilerAPIKey",
                userAgentPackageName: "com.example.spotsapp",
              ),
              // Draw small black dots for all their traces
              MarkerLayer(
                markers: moments
                    .map(
                      (m) => Marker(
                        point: m.location,
                        width: 14,
                        height: 14,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF335C81),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.3),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),

        // 2. AVATAR OVERLAPPING THE MAP
        Transform.translate(
          offset: const Offset(
            0,
            -50,
          ), // 🔹 Pulls the avatar UP so it sits halfway on the map
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.only(
                  top: 8,
                  left: 8,
                  right: 8,
                  bottom: 24,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: const BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage("https://picsum.photos/200"),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "@alex_explorer",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF335C81),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildStat("142", "Traces"),
                  Container(width: 1, height: 30, color: Colors.grey[300]),
                  _buildStat("38", "Spots"),
                  Container(width: 1, height: 30, color: Colors.grey[300]),
                  _buildStat("12k", "Steps"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // --- ROUTING FUNCTION FOR CARDS ---
  Widget _buildCard(Moment m) {
    switch (m.type) {
      case MomentType.photo:
        return _buildPhotoCard(m);
      case MomentType.text:
        return _buildTextCard(m);
      case MomentType.audio:
        return _buildAudioCard(m);
      case MomentType.map:
        return _buildMapCard(m);
    }
  }

  // --- DISTANCE STICKER UI ---
  Widget _buildDistanceStamp(Moment m) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2A7E6), // The nice pink from your gradient
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(
            _getFormattedDistance(m.location),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // --- INDIVIDUAL CARD DESIGNS ---

  Widget _buildCardWrapper(Moment moment, Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      child: Transform.rotate(
        angle: moment.rotation,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            // The Card Background
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: child,
            ),

            // "Washi Tape" detail
            Positioned(
              top: -8,
              child: Transform.rotate(
                angle: -0.1,
                child: Container(
                  width: 35,
                  height: 12,
                  color: Colors.grey[300]!.withOpacity(0.8),
                ),
              ),
            ),

            // 🔹 THE DISTANCE STAMP (Sticking out the bottom right)
            Positioned(
              bottom: -10,
              right: -5,
              child: Transform.rotate(
                // Counter-rotate the sticker so the text is always flat and readable!
                angle: -moment.rotation,
                child: _buildDistanceStamp(moment),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoCard(Moment m) {
    return _buildCardWrapper(
      m,
      Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: Image.network(m.content!, fit: BoxFit.cover),
            ),
            const SizedBox(height: 12),
            Text(
              m.title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              m.date,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 8), // Extra padding for the sticker
          ],
        ),
      ),
    );
  }

  Widget _buildTextCard(Moment m) {
    return _buildCardWrapper(
      m,
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFDF0),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.format_quote, color: Colors.black26, size: 20),
            const SizedBox(height: 4),
            Text(
              m.content!,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 12),
            Divider(color: Colors.black.withOpacity(0.1)),
            Text(
              "${m.title} • ${m.date}",
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioCard(Moment m) {
    final waveHeights = [10.0, 20.0, 15.0, 25.0, 12.0, 18.0, 10.0];
    return _buildCardWrapper(
      m,
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFE8F0FE),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.play_circle_fill,
                  color: Color(0xFF335C81),
                  size: 36,
                ),
                const SizedBox(width: 8),
                Row(
                  children: waveHeights
                      .map(
                        (h) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 3,
                          height: h,
                          decoration: BoxDecoration(
                            color: const Color(0xFF335C81).withOpacity(0.5),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              m.title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            Text(
              m.date,
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildMapCard(Moment m) {
    return _buildCardWrapper(
      m,
      Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.blueGrey[50],
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.blueGrey[100]!),
              ),
              child: Center(
                child: Icon(
                  Icons.map_outlined,
                  color: Colors.blueGrey[300],
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  size: 14,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    m.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              "${m.content} • ${m.date}",
              style: const TextStyle(color: Colors.grey, fontSize: 11),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
