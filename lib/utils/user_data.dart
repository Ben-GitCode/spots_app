import 'stamp_data.dart';
import 'collection_data.dart';
import 'moment_data.dart';

class UserData {
  final String id;
  final String username;
  final String profilePictureUrl;
  final DateTime dataJoined; 
  final int worldPercentage;
  final int contributionsCount;
  final List<Moment> userMoments; 
  final List<Collection> userCollections; 
  final List<Stamp> userStamps; 

  UserData({
    required this.id,
    required this.profilePictureUrl,
    required this.dataJoined,
    required this.worldPercentage,
    required this.contributionsCount,
    required this.username,
    required this.userMoments,
    required this.userCollections,
    required this.userStamps,  
  });

  factory UserData.fromJson(Map<String, dynamic> json) {
    return UserData(
      id: json['id'] ?? '', 
      username: json['username'] ?? 'Explorer', 
      profilePictureUrl: json['profile_picture'] ?? '',
      // For now, we "mock" the data you haven't built yet:
      dataJoined: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      worldPercentage: json['world_percentage'] ?? 0,
      contributionsCount: json['contributions_count'] ?? 0,
      userMoments: [],     // Empty list until you build the Moment table
      userCollections: [], // Empty list until you build the Collection logic
      userStamps: [],      // Empty list until you build the Stamp logic
    );
  }

}