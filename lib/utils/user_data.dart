import 'package:flutter/material.dart';
import 'stamp_data.dart';
import 'collection_data.dart';
import 'moment_data.dart';

class UserData {
  final String userID;
  final String username;
  final Image profilePicture;
  final DateTime dataJoined; 
  final int worldPercentage;
  final int contributionsCount;
  final List<Moment> userMoments; 
  final List<Collection> userCollections; 
  final List<Stamp> userStamps; 

  UserData({
    required this.userID,
    required this.profilePicture,
    required this.dataJoined,
    required this.worldPercentage,
    required this.contributionsCount,
    required this.username,
    required this.userMoments,
    required this.userCollections,
    required this.userStamps,  
  });
}