import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

class Moment {
  final String momentID;
  final String ownerID; 
  final Image previewImage; 
  final String text;
  final String mediaType; 
  final String mediaURL; 
  final String privacyType; 
  final LatLng location; 
  final DateTime dateCreated; 

  Moment({
    required this.momentID,
    required this.ownerID,
    required this.previewImage,
    required this.text,
    required this.mediaType,
    required this.mediaURL,
    required this.privacyType,
    required this.location,
    required this.dateCreated,
  });
}