import 'package:flutter/material.dart';
import 'stamp_data.dart';
import 'collection_data.dart';
import 'moment_data.dart';

class UserProvider extends ChangeNotifier {
  UserData? _currentUser;

  UserData? get currentUser => _currentUser;

  // Function to set the user after Signup/Login
  void setUser(UserData user) {
    _currentUser = user;
    notifyListeners(); // This tells all screens to rebuild with new data!
  }
}

class UserData {
  final String userID;
  final String username;
  final String profilePictureUrl;
  final DateTime dataJoined; 
  final int worldPercentage;
  final int contributionsCount;
  final List<Moment> userMoments; 
  final List<Collection> userCollections; 
  final List<Stamp> userStamps; 

  UserData({
    required this.userID,
    required this.profilePictureUrl,
    required this.dataJoined,
    required this.worldPercentage,
    required this.contributionsCount,
    required this.username,
    required this.userMoments,
    required this.userCollections,
    required this.userStamps,  
  });
}