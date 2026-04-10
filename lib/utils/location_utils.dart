import 'dart:convert';
import 'package:http/http.dart' as http;

Future<String> getAddressFromCoordinates(double lat, double lng) async {
  // 🔹 OpenStreetMap's free Nominatim API. No API key required!
  final url =
      'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1';

  try {
    final response = await http.get(
      Uri.parse(url),
      // Nominatim requires a User-Agent header to not block requests
      headers: {'User-Agent': 'SpotsApp/1.0'},
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final address = data['address'];

      // Attempt to get the street and house number, or fallback to neighborhood/city
      final road =
          address['road'] ??
          address['pedestrian'] ??
          address['suburb'] ??
          'Unknown Spot';
      final houseNumber = address['house_number'] ?? '';

      return '$road $houseNumber'.trim();
    }
  } catch (e) {
    print("Geocoding error: $e");
  }

  return "Unknown Location"; // Fallback if no internet or map data
}
