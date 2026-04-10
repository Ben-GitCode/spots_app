import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

// 1. ENUMS
enum SpotTypes { public, private, me }

enum SpotReactions {
  funny,
  wow,
  sad,
  insightful,
  support,
  meh,
  wholesome,
  empty,
}

// // 🔹 THE UPGRADE: This makes the emoji accessible anywhere you use the enum!
// extension SpotReactionsExtension on SpotReactions {
//   String get emoji {
//     switch (this) {
//       case SpotReactions.funny:
//         return "\u{1F602}";
//       case SpotReactions.wow:
//         return "\u{1F62E}";
//       case SpotReactions.sad:
//         return "\u{1F622}";
//       case SpotReactions.insightful:
//         return "\u{1F4A1}";
//       case SpotReactions.support:
//         // return "\u{1F4AA}";
//         return "\u{1F525}";
//       case SpotReactions.meh:
//         return "\u{1F615}";
//       case SpotReactions.wholesome:
//         return "\u{1F970}";
//       case SpotReactions.empty:
//         return "\u{2754}";
//     }
//   }
// }

extension SpotReactionsExtension on SpotReactions {
  String get assetPath {
    switch (this) {
      case SpotReactions.funny:
        return "assets/emojis/emoji_u1f602.png";
      case SpotReactions.wow:
        return "assets/emojis/emoji_u1f62f.png";
      case SpotReactions.sad:
        return "assets/emojis/emoji_u1f622.png";
      case SpotReactions.insightful:
        return "assets/emojis/emoji_u1f4a1.png";
      case SpotReactions.support:
        return "assets/emojis/emoji_u1f525.png";
      case SpotReactions.meh:
        return "assets/emojis/emoji_u1f615.png";
      case SpotReactions.wholesome:
        return "assets/emojis/emoji_u1f970.png";
      case SpotReactions.empty:
        return "assets/emojis/emoji_u2754.png";
    }
  }

  // 🔹 NEW: The Animated WebPs (Used ONLY in the bottom sheet selector)
  String get animatedAssetPath {
    switch (this) {
      case SpotReactions.funny:
        return "assets/animated/funny.webp";
      case SpotReactions.wow:
        return "assets/animated/wow.webp";
      case SpotReactions.sad:
        return "assets/animated/sad.webp";
      case SpotReactions.insightful:
        return "assets/animated/insightful.webp";
      case SpotReactions.support:
        return "assets/animated/support.webp";
      case SpotReactions.meh:
        return "assets/animated/meh.webp";
      case SpotReactions.wholesome:
        return "assets/animated/wholesome.webp";
      case SpotReactions.empty:
        return "assets/animated/empty.webp";
    }
  }
}

// 2. THE CLASS
class Spot {
  final String id; // Unique ID to track selection
  final String ownerId; // Supabase "user_id"
  final String title;
  final String description;
  final LatLng location;
  final SpotTypes type;

  final Map<SpotReactions, int> reactionCounts;

  Spot({
    required this.id,
    required this.ownerId,
    required this.title,
    required this.description,
    required this.location,
    required this.type,
    required this.reactionCounts,
  });

  // --- LOGIC: GET TOP REACTION ---
  SpotReactions get topReaction {
    if (reactionCounts.isEmpty) return SpotReactions.empty; // Default fallback

    // Sorts the map entries by value (count) and returns the key (reaction) of the highest one
    var sortedEntries = reactionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value)); // Descending order

    return sortedEntries.first.key;
  }

  // 3. LOGIC: Get colors based on Type
  Color get outlineColor {
    switch (type) {
      case SpotTypes.public:
        return Color.fromARGB(255, 164, 193, 244);
      case SpotTypes.private:
        return Color.fromARGB(255, 182, 215, 168);
      case SpotTypes.me:
        return Color.fromARGB(255, 255, 229, 153);
    }
  }

  Color get innerColor {
    switch (type) {
      case SpotTypes.public:
        return Color.fromARGB(255, 109, 158, 235);
      case SpotTypes.private:
        return Color.fromARGB(255, 147, 196, 125);
      case SpotTypes.me:
        return Color.fromRGBO(242, 203, 7, 1);
    }
  }

  // 4. LOGIC: Get emoji based on Reaction
  // String getEmojiForReaction(SpotReactions r) {
  //   switch (r) {
  //     case SpotReactions.funny:
  //       return "\u{1F602}"; // Laughing Emoji
  //     case SpotReactions.wow:
  //       return "\u{1F62E}"; // Shocked Emoji
  //     case SpotReactions.sad:
  //       return "\u{1F622}"; // Emoji with tear
  //     case SpotReactions.insightful:
  //       return "\u{1F4A1}"; // Lightbulb
  //     case SpotReactions.support:
  //       return "\u{1F4AA}"; // Bicep
  //     case SpotReactions.meh:
  //       return "\u{1F615}"; // Meh Emoji
  //     case SpotReactions.wholesome:
  //       return "\u{1F60D}"; // Heart Eyes
  //     case SpotReactions.empty:
  //       return "\u{2754}"; // Question Mark
  //   }
  // }

  // 4. LOGIC: Get top reaction asset path
  String get topReactionAsset => topReaction.assetPath;

  factory Spot.fromJson(Map<String, dynamic> json) {
    // 1. Parse Location (Supabase usually returns GeoJSON or raw lat/lng columns)
    final lat = json['latitude'] as double;
    final lng = json['longitude'] as double;

    // 2. Parse Reactions (Database will likely give us a Map<String, int>)
    // We iterate over the raw JSON map and convert keys string 'love' -> Enum SpotReaction.love
    Map<SpotReactions, int> parsedReactions = {};
    if (json['reactions'] != null) {
      (json['reactions'] as Map<String, dynamic>).forEach((key, value) {
        // Find the enum that matches the string key
        SpotReactions? reactionEnum = SpotReactions.values.firstWhere(
          (e) => e.name == key,
          orElse: () => SpotReactions.empty,
        );
        parsedReactions[reactionEnum] = value as int;
      });
    }

    return Spot(
      id: json['id'],
      ownerId: json['owner_id'],
      title: json['title'],
      description: json['description'] ?? "",
      location: LatLng(lat, lng),
      // Convert string 'public' -> SpotType.public
      type: SpotTypes.values.firstWhere((e) => e.name == json['type']),
      reactionCounts: parsedReactions,
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
      'type': type.name, // Saves "public" instead of "SpotType.public"
      // Convert Enum Map -> String Map for DB
      'reactions': reactionCounts.map(
        (key, value) => MapEntry(key.name, value),
      ),
    };
  }
}
