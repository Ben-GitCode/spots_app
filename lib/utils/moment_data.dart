import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:spots_app/utils/models.dart';
import 'package:spots_app/media_widgets/moment_media_blocks.dart';

class Moment {
  final String id;
  final String spotId; // 🔹 NEW: Used to navigate back to the Spot
  final String authorId; // 🔹 NEW: Used to navigate to the User Profile
  final String authorName;
  final String avatarUrl;
  final DateTime timestamp;
  final MomentMedia media;
  final String caption;
  final Map<Reactions, int> reactionCounts;
  final int commentCount;
  final LatLng location;

  Reactions? userReaction;

  Moment({
    required this.id,
    required this.spotId,
    required this.authorId,
    required this.authorName,
    required this.avatarUrl,
    required this.timestamp,
    required Map<String, dynamic>? payload,
    required this.reactionCounts,
    required this.location,
    this.caption = "",
    this.commentCount = 0,
    this.userReaction,
  }) : media = MomentMedia.fromData(payload, caption);

  // --- LOGIC: AGGREGATE REACTIONS ---
  int get totalReactions =>
      reactionCounts.values.fold(0, (sum, val) => sum + val);

  List<Reactions> get top3Reactions {
    var sortedEntries = reactionCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sortedEntries.take(3).map((e) => e.key).toList();
  }

  // --- SUPABASE PARSER ---
  factory Moment.fromMap(Map<String, dynamic> map) {
    // 1. Grab the raw payload exactly as it is in the database (null is fine!)
    final payload = map['media_payload'];
    final String caption = map['caption'] ?? '';

    // 2. Extract Location
    final locData = map['location'];
    double lat = 0.0;
    double lng = 0.0;
    if (locData is Map && locData.containsKey('coordinates')) {
      List coords = locData['coordinates'];
      lng = coords[0].toDouble();
      lat = coords[1].toDouble();
    }

    // 3. Extract joined profile data
    final profile = map['users'] ?? {};
    Map<Reactions, int> parsedReactions = {};

    return Moment(
      id: map['id'].toString(),
      spotId: map['spot_id']?.toString() ?? '',
      authorId: map['user_id']?.toString() ?? '',
      authorName: profile['username'] ?? 'Unknown User',
      avatarUrl: profile['profile_picture'] ?? 'https://i.pravatar.cc/150',
      timestamp: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
      payload: payload, // 🔹 Passes raw payload (might be null)
      caption: caption, // 🔹 Passes SQL caption
      location: LatLng(lat, lng),
      commentCount: map['comment_count'] ?? 0,
      reactionCounts: parsedReactions,
    );
  }
}
