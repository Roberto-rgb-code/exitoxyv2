import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleStreetViewService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/streetview';
  String? _apiKey;

  GoogleStreetViewService() {
    _apiKey = dotenv.env['GOOGLE_STREET_VIEW_API_KEY'] ?? dotenv.env['GOOGLE_PLACES_API_KEY'];
  }

  /// Obtener URL de imagen de Street View
  String getStreetViewImageUrl({
    required double latitude,
    required double longitude,
    int width = 400,
    int height = 300,
    int fov = 90,
    int pitch = 0,
    String? heading,
  }) {
    final params = {
      'size': '${width}x$height',
      'location': '$latitude,$longitude',
      'fov': fov.toString(),
      'pitch': pitch.toString(),
      'key': _apiKey!,
    };

    if (heading != null) params['heading'] = heading;

    final uri = Uri.parse('$_baseUrl').replace(queryParameters: params);
    return uri.toString();
  }

  /// Obtener metadatos de Street View para una ubicación
  Future<StreetViewMetadata?> getStreetViewMetadata({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final url = 'https://maps.googleapis.com/maps/api/streetview/metadata';
      final params = {
        'location': '$latitude,$longitude',
        'key': _apiKey!,
      };

      final uri = Uri.parse(url).replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return StreetViewMetadata.fromJson(data);
        }
      }
      return null;
    } catch (e) {
      print('Error obteniendo metadatos de Street View: $e');
      return null;
    }
  }

  /// Verificar si hay Street View disponible para una ubicación
  Future<bool> isStreetViewAvailable({
    required double latitude,
    required double longitude,
  }) async {
    final metadata = await getStreetViewMetadata(
      latitude: latitude,
      longitude: longitude,
    );
    return metadata != null && metadata.status == 'OK';
  }

  /// Obtener múltiples vistas de Street View (360 grados)
  List<String> get360StreetViewUrls({
    required double latitude,
    required double longitude,
    int width = 400,
    int height = 300,
    int fov = 90,
    int pitch = 0,
    int numViews = 8, // Número de vistas (cada 45 grados)
  }) {
    final List<String> urls = [];
    
    for (int i = 0; i < numViews; i++) {
      final heading = (i * 360 / numViews).round();
      final url = getStreetViewImageUrl(
        latitude: latitude,
        longitude: longitude,
        width: width,
        height: height,
        fov: fov,
        pitch: pitch,
        heading: heading.toString(),
      );
      urls.add(url);
    }
    
    return urls;
  }

  /// Obtener vista de Street View con diferentes ángulos
  Map<String, String> getStreetViewAngles({
    required double latitude,
    required double longitude,
    int width = 400,
    int height = 300,
    int fov = 90,
  }) {
    return {
      'north': getStreetViewImageUrl(
        latitude: latitude,
        longitude: longitude,
        width: width,
        height: height,
        fov: fov,
        heading: '0',
      ),
      'east': getStreetViewImageUrl(
        latitude: latitude,
        longitude: longitude,
        width: width,
        height: height,
        fov: fov,
        heading: '90',
      ),
      'south': getStreetViewImageUrl(
        latitude: latitude,
        longitude: longitude,
        width: width,
        height: height,
        fov: fov,
        heading: '180',
      ),
      'west': getStreetViewImageUrl(
        latitude: latitude,
        longitude: longitude,
        width: width,
        height: height,
        fov: fov,
        heading: '270',
      ),
    };
  }

  /// Obtener vista panorámica de Street View
  String getPanoramaUrl({
    required double latitude,
    required double longitude,
    int width = 800,
    int height = 400,
    int fov = 120,
    int pitch = 0,
  }) {
    return getStreetViewImageUrl(
      latitude: latitude,
      longitude: longitude,
      width: width,
      height: height,
      fov: fov,
      pitch: pitch,
    );
  }
}

class StreetViewMetadata {
  final String status;
  final String? copyright;
  final String? date;
  final String? location;
  final double? latitude;
  final double? longitude;
  final String? panoId;

  StreetViewMetadata({
    required this.status,
    this.copyright,
    this.date,
    this.location,
    this.latitude,
    this.longitude,
    this.panoId,
  });

  factory StreetViewMetadata.fromJson(Map<String, dynamic> json) {
    final location = json['location'];
    
    return StreetViewMetadata(
      status: json['status'] ?? '',
      copyright: json['copyright'],
      date: json['date'],
      location: json['location']?['formatted_address'],
      latitude: location?['lat']?.toDouble(),
      longitude: location?['lng']?.toDouble(),
      panoId: json['pano_id'],
    );
  }

  bool get isAvailable => status == 'OK';
}
