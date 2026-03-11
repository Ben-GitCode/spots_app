import 'package:flutter/material.dart';
import 'package:spots_app/utils/models.dart';

class SpotDetailsScreen extends StatelessWidget {
  final Spot spot;

  const SpotDetailsScreen({super.key, required this.spot});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(spot.title),
        backgroundColor: spot.outlineColor,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Center(
              child: Text(spot.topEmoji, style: const TextStyle(fontSize: 80)),
            ),
            const SizedBox(height: 20),
            Text(spot.description, style: const TextStyle(fontSize: 18)),
            const Spacer(),
            ElevatedButton(
              onPressed: () {},
              child: const Text("Navigate Here"),
            ),
          ],
        ),
      ),
    );
  }
}
