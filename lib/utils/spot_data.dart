import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:spots_app/utils/models.dart';

class Spot {
  final String id; // Unique ID to track selection
  final String ownerId; // Supabase "user_id"
  final String title;
  final String description;
  final LatLng location;
  final PrivacyTypes type;
  final Map<Reactions, int> reactionCounts;

  // 🔹 NEW: Rich location data
  final String timezone;
  final Map<String, dynamic> addressJson;

  Spot({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.location,
    required this.type,
    required this.reactionCounts,
    required this.timezone,
    required this.addressJson,
  });

  // --- LOGIC: GET TOP REACTION ---
  Reactions get topReaction {
    if (reactionCounts.isEmpty) return Reactions.empty; // Default fallback

    // Sorts the map entries by value (count) and returns the key (reaction) of the highest one
    var sortedEntries = reactionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Descending order

    return sortedEntries.first.key;
  }

  // 3. LOGIC: Get colors based on Type
  Color get outlineColor {
    switch (type) {
      case PrivacyTypes.public:
        return const Color.fromARGB(255, 164, 193, 244);
      case PrivacyTypes.private:
        return const Color.fromARGB(255, 182, 215, 168);
      case PrivacyTypes.me:
        return const Color.fromARGB(255, 255, 229, 153);
    }
  }

  Color get innerColor {
    switch (type) {
      case PrivacyTypes.public:
        return const Color.fromARGB(255, 109, 158, 235);
      case PrivacyTypes.private:
        return const Color.fromARGB(255, 147, 196, 125);
      case PrivacyTypes.me:
        return const Color.fromRGBO(242, 203, 7, 1);
    }
  }

  // 4. LOGIC: Get top reaction asset path
  String get topReactionAsset => topReaction.assetPath;

  // ==========================================
  // 🔹 UI HELPERS: CLEAN ADDRESS STRINGS
  // ==========================================

  String get displayLocation {
    if (addressJson['status'] != 'success') return "Unknown Location";

    // Try to get the city, fall back to the district if city is empty
    String city = addressJson['locality']?.toString().trim() ?? '';
    if (city.isEmpty) {
      city = addressJson['sub_admin_area']?.toString().trim() ?? '';
    }

    String country = addressJson['country']?.toString().trim() ?? '';

    // Glues them together nicely
    final parts = [city, country].where((p) => p.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : "Unknown Location";
  }

  String get fullStreetAddress {
    if (addressJson['status'] != 'success') return "Location pinned";

    // Try street first, then thoroughfare
    String street = addressJson['street']?.toString().trim() ?? '';
    if (street.isEmpty) {
      street = addressJson['thoroughfare']?.toString().trim() ?? '';
    }

    return street.isNotEmpty ? street : displayLocation;
  }

  String get popupAddressLine1 {
    if (addressJson['status'] != 'success') return "Unknown Address";

    String street = addressJson['street']?.toString().trim() ?? '';
    if (street.isEmpty) {
      street = addressJson['sub_admin_area']?.toString().trim() ?? '';
    }
    if (street.isEmpty) {
      street = addressJson['admin_area']?.toString().trim() ?? '';
    }
    // Glues them together nicely
    final parts = [street].where((p) => p.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : "Unknown Address";
  }

  String get popupAddressLine2 {
    if (addressJson['status'] != 'success') return "Unknown Country";

    String locality = addressJson['locality']?.toString().trim() ?? '';
    String country = addressJson['country']?.toString().trim() ?? '';
    String adminArea = '';

    if (country == "United States") {
      adminArea = addressJson['admin_area']?.toString().trim() ?? '';
      country = 'USA';
    }

    // Glues them together nicely
    final parts = [
      locality,
      adminArea,
      country,
    ].where((p) => p.isNotEmpty).toList();
    return parts.isNotEmpty ? parts.join(', ') : "Unknown Location";
  }

  // ==========================================
  // 🔹 ROBUST FACTORY PARSER
  // ==========================================
  factory Spot.fromJson(Map<String, dynamic> json) {
    // 1. Safe Location Parsing (Handles both raw lat/lng AND PostGIS Geography objects)
    double lat = 0.0;
    double lng = 0.0;

    final locData = json['location'];
    if (locData is Map && locData.containsKey('coordinates')) {
      List coords = locData['coordinates'];
      lng = coords[0].toDouble();
      lat = coords[1].toDouble();
    } else {
      lat = (json['latitude'] ?? 0.0).toDouble();
      lng = (json['longitude'] ?? 0.0).toDouble();
    }

    // 2. Safe Reaction Parsing
    Map<Reactions, int> parsedReactions = {};
    if (json['reactions'] != null && json['reactions'] is Map) {
      (json['reactions'] as Map<String, dynamic>).forEach((key, value) {
        Reactions reactionEnum = Reactions.values.firstWhere(
          (e) => e.name == key,
          orElse: () => Reactions.empty,
        );
        parsedReactions[reactionEnum] = value as int;
      });
    }

    // 3. Safe Type Parsing (Defaults to public if null/unknown)
    PrivacyTypes parsedType = PrivacyTypes.public;
    if (json['type'] != null) {
      parsedType = PrivacyTypes.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => PrivacyTypes.public,
      );
    }

    // 4. Safe Address JSON Parsing
    Map<String, dynamic> parsedAddress = {};
    if (json['address'] != null && json['address'] is Map) {
      parsedAddress = Map<String, dynamic>.from(json['address']);
    }

    return Spot(
      id: json['id']?.toString() ?? '',
      ownerId: json['owner_id']?.toString() ?? '',
      title: json['title'] ?? 'Unknown Spot',
      description: json['description'] ?? "",
      location: LatLng(lat, lng),
      type: parsedType,
      reactionCounts: parsedReactions,
      timezone: json['timezone']?.toString() ?? '',
      addressJson: parsedAddress,
    );
  }

  // Convert Dart Object -> Database JSON (for saving)
  Map<String, dynamic> toJson() {
    return {
      'owner_id': ownerId,
      'title': title,
      'description': description,
      'latitude': location.latitude,
      'longitude': location.longitude,
      'type': type.name,
      'timezone': timezone,
      'address': addressJson,
      'reactions': reactionCounts.map(
        (key, value) => MapEntry(key.name, value),
      ),
    };
  }
}
