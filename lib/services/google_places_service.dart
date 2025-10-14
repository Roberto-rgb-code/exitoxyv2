// lib/services/google_places_service.dart
import 'dart:convert';
import 'dart:ui' as ui; // para ui.Offset
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class GooglePlaceService {
  static Future<List<Map<String, dynamic>>> getPlacesNearby(
    String keyword,
    double lat,
    double lon, {
    int radius = 1500,
    String language = 'es-419',
  }) async {
    final List<Map<String, dynamic>> negocios = [];

    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json'
      '?keyword=$keyword'
      '&location=$lat%2C$lon'
      '&radius=$radius'
      '&key=${Config.googlePlacesApiKey}'
      '&language=$language',
    );

    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('Error Places: ${response.statusCode}');
    }

    final data = json.decode(response.body);
    if (data['results'] is List) {
      for (final e in data['results']) {
        try {
          negocios.add({
            'lat': (e["geometry"]["location"]["lat"] as num).toDouble(),
            'lon': (e["geometry"]["location"]["lng"] as num).toDouble(),
            'nombre': (e["name"] ?? '').toString(),
            'direccion': (e["vicinity"] ?? '').toString(),
          });
        } catch (_) {}
      }
    }
    return negocios;
  }

  /// Marcador simple (infoWindow nativo)
  static Future<Marker> buildSimpleMarker(
    String id,
    LatLng pos,
    String title,
  ) async {
    final icon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
    return Marker(
      markerId: MarkerId(id),
      position: pos,
      icon: icon,
      anchor: const ui.Offset(0.5, 1), // usa dart:ui
      infoWindow: InfoWindow(title: title),
    );
  }
}
