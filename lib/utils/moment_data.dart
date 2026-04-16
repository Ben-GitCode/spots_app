import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class Moment {
  final String momentID;
  final String ownerID;
  final String text; 
  final String mediaURL; 
  final String mediaType; // Added mediaType field
  final LatLng location;
  final DateTime dateCreated;

  Moment({
    required this.momentID,
    required this.ownerID,
    required this.text,
    required this.mediaURL,
    required this.mediaType, // Required in constructor
    required this.location,
    required this.dateCreated,
  });

  factory Moment.fromMap(Map<String, dynamic> map) {
  // --- 1. Extract Media ---
  final payload = map['media_payload'];
  String url = '';
  String type = 'photo';

  if (payload is Map<String, dynamic>) {
    // For music, you might want the album art as the preview
    type = payload['type'] ?? 'photo';
    url = (type == 'music' || type == 'sound') 
        ? (payload['album_art'] ?? '') 
        : (payload['url'] ?? '');
  }

  // --- 2. Extract Location (Handling PostGIS Geography) ---
  final locData = map['location'];
  double lat = 0.0;
  double lng = 0.0;

  if (locData is Map && locData.containsKey('coordinates')) {
    // GeoJSON format: [longitude, latitude]
    List coords = locData['coordinates'];
    lng = coords[0].toDouble();
    lat = coords[1].toDouble();
  } else if (locData is String) {
    // This catches that hex string so the app doesn't crash, 
    // even if it can't plot the point yet.
    print("Warning: Location is still a hex string. Query for 'location' as GeoJSON.");
  }

  return Moment(
    momentID: map['id'].toString(),
    ownerID: map['user_id'].toString(),
    text: map['caption'] ?? '',
    mediaURL: url,
    mediaType: type,
    location: LatLng(lat, lng),
    dateCreated: map['created_at'] != null 
        ? DateTime.parse(map['created_at']) 
        : DateTime.now(),
  );
}
}