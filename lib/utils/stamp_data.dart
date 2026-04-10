import 'package:flutter/material.dart';

class Stamp{
  final String stampID;
  final Image stampImage; // or icon instead of image?
  final DateTime dateCreated;
  final String momentID;

  Stamp({
      required this.stampID,
      required this.stampImage,
      required this.dateCreated,
      required this.momentID,
    });
}