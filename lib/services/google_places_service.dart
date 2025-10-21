import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GooglePlacesService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  String? _apiKey;

  GooglePlacesService() {
    _apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
  }

  /// Buscar lugares cerca de una ubicación
  Future<List<PlaceResult>> searchNearby({
    required double latitude,
    required double longitude,
    double radius = 1000, // metros
    String? type, // restaurant, hospital, school, etc.
    String? keyword,
  }) async {
    try {
      final url = '$_baseUrl/nearbysearch/json';
      final params = {
        'location': '$latitude,$longitude',
        'radius': radius.toString(),
        'key': _apiKey!,
      };

      if (type != null) params['type'] = type;
      if (keyword != null) params['keyword'] = keyword;

      final uri = Uri.parse(url).replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return results.map((result) => PlaceResult.fromJson(result)).toList();
        } else {
          throw Exception('Error de API: ${data['status']}');
        }
      } else {
        throw Exception('Error HTTP: ${response.statusCode}');
      }
    } catch (e) {
      print('Error en Google Places API: $e');
      return [];
    }
  }

  /// Obtener detalles de un lugar específico
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    try {
      final url = '$_baseUrl/details/json';
      final params = {
        'place_id': placeId,
        'fields': 'name,rating,formatted_phone_number,website,opening_hours,reviews,photos',
        'key': _apiKey!,
      };

      final uri = Uri.parse(url).replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return PlaceDetails.fromJson(data['result']);
        }
      }
      return null;
    } catch (e) {
      print('Error obteniendo detalles del lugar: $e');
      return null;
    }
  }

  /// Buscar lugares por texto
  Future<List<PlaceResult>> searchByText({
    required String query,
    double? latitude,
    double? longitude,
    double radius = 50000, // metros
  }) async {
    try {
      final url = '$_baseUrl/textsearch/json';
      final params = {
        'query': query,
        'key': _apiKey!,
      };

      if (latitude != null && longitude != null) {
        params['location'] = '$latitude,$longitude';
        params['radius'] = radius.toString();
      }

      final uri = Uri.parse(url).replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final results = data['results'] as List;
          return results.map((result) => PlaceResult.fromJson(result)).toList();
        }
      }
      return [];
    } catch (e) {
      print('Error en búsqueda por texto: $e');
      return [];
    }
  }

  /// Obtener lugares por tipo específico
  Future<List<PlaceResult>> getPlacesByType({
    required double latitude,
    required double longitude,
    required String type,
    double radius = 1000,
  }) async {
    return searchNearby(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      type: type,
    );
  }

  /// Obtener servicios esenciales (hospitales, escuelas, transporte)
  Future<Map<String, List<PlaceResult>>> getEssentialServices({
    required double latitude,
    required double longitude,
    double radius = 1000,
  }) async {
    final services = <String, List<PlaceResult>>{};
    
    final types = [
      'hospital',
      'school',
      'transit_station',
      'gas_station',
      'pharmacy',
      'police',
      'fire_station',
    ];

    for (final type in types) {
      final places = await getPlacesByType(
        latitude: latitude,
        longitude: longitude,
        type: type,
        radius: radius,
      );
      services[type] = places;
    }

    return services;
  }
}

class PlaceResult {
  final String placeId;
  final String name;
  final double rating;
  final int userRatingsTotal;
  final String vicinity;
  final double latitude;
  final double longitude;
  final List<String> types;
  final String? photoReference;
  final bool isOpen;

  PlaceResult({
    required this.placeId,
    required this.name,
    required this.rating,
    required this.userRatingsTotal,
    required this.vicinity,
    required this.latitude,
    required this.longitude,
    required this.types,
    this.photoReference,
    required this.isOpen,
  });

  factory PlaceResult.fromJson(Map<String, dynamic> json) {
    final location = json['geometry']['location'];
    final openingHours = json['opening_hours'];
    
    return PlaceResult(
      placeId: json['place_id'] ?? '',
      name: json['name'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      userRatingsTotal: json['user_ratings_total'] ?? 0,
      vicinity: json['vicinity'] ?? '',
      latitude: (location['lat'] ?? 0.0).toDouble(),
      longitude: (location['lng'] ?? 0.0).toDouble(),
      types: List<String>.from(json['types'] ?? []),
      photoReference: json['photos']?.isNotEmpty == true 
          ? json['photos'][0]['photo_reference'] 
          : null,
      isOpen: openingHours?['open_now'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'rating': rating,
      'userRatingsTotal': userRatingsTotal,
      'vicinity': vicinity,
      'latitude': latitude,
      'longitude': longitude,
      'types': types,
      'photoReference': photoReference,
      'isOpen': isOpen,
    };
  }
}

class PlaceDetails {
  final String name;
  final double rating;
  final String? formattedPhoneNumber;
  final String? website;
  final List<String>? openingHours;
  final List<Review>? reviews;
  final List<String>? photoReferences;

  PlaceDetails({
    required this.name,
    required this.rating,
    this.formattedPhoneNumber,
    this.website,
    this.openingHours,
    this.reviews,
    this.photoReferences,
  });

  factory PlaceDetails.fromJson(Map<String, dynamic> json) {
    final openingHours = json['opening_hours']?['weekday_text'];
    final reviews = json['reviews'] as List?;
    final photos = json['photos'] as List?;

    return PlaceDetails(
      name: json['name'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      formattedPhoneNumber: json['formatted_phone_number'],
      website: json['website'],
      openingHours: openingHours != null 
          ? List<String>.from(openingHours) 
          : null,
      reviews: reviews?.map((r) => Review.fromJson(r)).toList(),
      photoReferences: photos?.map((p) => p['photo_reference']).cast<String>().toList(),
    );
  }
}

class Review {
  final String authorName;
  final double rating;
  final String text;
  final int time;

  Review({
    required this.authorName,
    required this.rating,
    required this.text,
    required this.time,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      authorName: json['author_name'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      text: json['text'] ?? '',
      time: json['time'] ?? 0,
    );
  }
}