import 'package:flutter/material.dart';
import 'moment_data.dart';

class Collection{
  final String collectionID;
  final List<Moment> moments; 
  final String title;
  final String privacyType; 
  final Image previewImage; 
  final DateTime dateCreated; 

  Collection({
    required this.collectionID,
    required this.moments,
    required this.title,
    required this.privacyType,
    required this.previewImage,
    required this.dateCreated,
  });
}