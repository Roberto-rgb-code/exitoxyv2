import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

const String placesApiKey = String.fromEnvironment('PLACES_API_KEY');

class GooglePlacesService {
  static Future<List<Map<String, dynamic>>> nearby({
    required String keyword,
    required LatLng center,
    int radius = 1500,
    String language = 'es-419',
  }) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?keyword=$keyword'
      '&location=${center.latitude}%2C${center.longitude}'
      '&radius=$radius&key=$placesApiKey&language=$language',
    );
    final r = await http.get(url);
    if (r.statusCode != 200) throw Exception('Places error ${r.statusCode}');
    final data = json.decode(r.body);
    final List out = data['results'] ?? [];
    return out.map<Map<String, dynamic>>((e) => {
      'lat': e['geometry']['location']['lat'],
      'lon': e['geometry']['location']['lng'],
      'nombre': e['name'],
      'direccion': e['vicinity'],
    }).toList();
  }
}
