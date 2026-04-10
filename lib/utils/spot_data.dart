import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'moment_data.dart';

class Spot {
    final String spotID;
    final String addressID; 
    final String discoveredByUserID; 
    final List<Moment> moments; 
    final Icon spotDominantIcon; 
    final String mediaType; 
    final int reactionsCount; 
    final String privacyType; 
    final LatLng location; 
    final DateTime dateCreated; 

    Spot({
      required this.spotID,
      required this.addressID,
      required this.discoveredByUserID,
      required this.moments,
      required this.spotDominantIcon,
      required this.mediaType,
      required this.reactionsCount,
      required this.privacyType,
      required this.location,
      required this.dateCreated,
    });
}