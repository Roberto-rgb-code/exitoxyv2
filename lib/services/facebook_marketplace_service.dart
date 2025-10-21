import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class FacebookMarketplaceService {
  static const String _baseUrl = 'https://graph.facebook.com/v18.0';
  String? _accessToken;
  String? _appId;

  FacebookMarketplaceService() {
    _accessToken = dotenv.env['FACEBOOK_ACCESS_TOKEN'];
    _appId = dotenv.env['FACEBOOK_APP_ID'];
  }

  /// Buscar propiedades en Marketplace cerca de una ubicación
  Future<List<MarketplaceListing>> searchMarketplaceListings({
    required double latitude,
    required double longitude,
    double radius = 5000, // metros
    String? category,
    double? minPrice,
    double? maxPrice,
    int limit = 50,
  }) async {
    try {
      final url = '$_baseUrl/search';
      final params = {
        'type': 'place',
        'q': 'renta departamento casa',
        'center': '$latitude,$longitude',
        'distance': radius.toString(),
        'access_token': _accessToken!,
        'fields': 'id,name,location,description,link,picture,price_range',
        'limit': limit.toString(),
      };

      if (category != null) params['category'] = category;
      if (minPrice != null) params['min_price'] = minPrice.toString();
      if (maxPrice != null) params['max_price'] = maxPrice.toString();

      final uri = Uri.parse(url).replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final results = data['data'] as List;
          return results.map((result) => MarketplaceListing.fromJson(result)).toList();
        }
      }
      
      print('Error en Facebook Marketplace API: ${response.statusCode} - ${response.body}');
      return [];
    } catch (e) {
      print('Error buscando en Facebook Marketplace: $e');
      return [];
    }
  }

  /// Buscar propiedades por texto
  Future<List<MarketplaceListing>> searchByText({
    required String query,
    double? latitude,
    double? longitude,
    double radius = 5000,
    int limit = 50,
  }) async {
    try {
      final url = '$_baseUrl/search';
      final params = {
        'type': 'place',
        'q': query,
        'access_token': _accessToken!,
        'fields': 'id,name,location,description,link,picture,price_range',
        'limit': limit.toString(),
      };

      if (latitude != null && longitude != null) {
        params['center'] = '$latitude,$longitude';
        params['distance'] = radius.toString();
      }

      final uri = Uri.parse(url).replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final results = data['data'] as List;
          return results.map((result) => MarketplaceListing.fromJson(result)).toList();
        }
      }
      
      return [];
    } catch (e) {
      print('Error buscando por texto en Facebook Marketplace: $e');
      return [];
    }
  }

  /// Obtener categorías disponibles
  Future<List<String>> getAvailableCategories() async {
    try {
      final url = '$_baseUrl/search';
      final params = {
        'type': 'placetopic',
        'access_token': _accessToken!,
        'limit': '100',
      };

      final uri = Uri.parse(url).replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          final results = data['data'] as List;
          return results.map((result) => result['name'].toString()).toList();
        }
      }
      
      return [
        'Apartamentos',
        'Casas',
        'Estudios',
        'Habitaciones',
        'Oficinas',
        'Locales',
        'Terrenos',
      ];
    } catch (e) {
      print('Error obteniendo categorías: $e');
      return [
        'Apartamentos',
        'Casas',
        'Estudios',
        'Habitaciones',
        'Oficinas',
        'Locales',
        'Terrenos',
      ];
    }
  }

  /// Obtener estadísticas de precios por área
  Future<Map<String, dynamic>> getPriceStatistics({
    required double latitude,
    required double longitude,
    double radius = 2000,
  }) async {
    try {
      final listings = await searchMarketplaceListings(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        limit: 100,
      );

      if (listings.isEmpty) {
        return {
          'averagePrice': 0.0,
          'minPrice': 0.0,
          'maxPrice': 0.0,
          'totalListings': 0,
          'priceRange': {},
        };
      }

      final prices = listings
          .where((listing) => listing.priceRange != null)
          .map((listing) => listing.priceRange!)
          .toList();

      if (prices.isEmpty) {
        return {
          'averagePrice': 0.0,
          'minPrice': 0.0,
          'maxPrice': 0.0,
          'totalListings': listings.length,
          'priceRange': {},
        };
      }

      final averagePrice = prices.reduce((a, b) => a + b) / prices.length;
      final minPrice = prices.reduce((a, b) => a < b ? a : b);
      final maxPrice = prices.reduce((a, b) => a > b ? a : b);

      // Distribución de precios por rangos
      final priceRange = <String, int>{};
      for (final price in prices) {
        if (price < 5000) {
          priceRange['< \$5,000'] = (priceRange['< \$5,000'] ?? 0) + 1;
        } else if (price < 10000) {
          priceRange['\$5,000 - \$10,000'] = (priceRange['\$5,000 - \$10,000'] ?? 0) + 1;
        } else if (price < 15000) {
          priceRange['\$10,000 - \$15,000'] = (priceRange['\$10,000 - \$15,000'] ?? 0) + 1;
        } else if (price < 20000) {
          priceRange['\$15,000 - \$20,000'] = (priceRange['\$15,000 - \$20,000'] ?? 0) + 1;
        } else {
          priceRange['> \$20,000'] = (priceRange['> \$20,000'] ?? 0) + 1;
        }
      }

      return {
        'averagePrice': averagePrice,
        'minPrice': minPrice,
        'maxPrice': maxPrice,
        'totalListings': listings.length,
        'priceRange': priceRange,
      };
    } catch (e) {
      print('Error obteniendo estadísticas de precios: $e');
      return {
        'averagePrice': 0.0,
        'minPrice': 0.0,
        'maxPrice': 0.0,
        'totalListings': 0,
        'priceRange': {},
      };
    }
  }

  /// Obtener propiedades recomendadas basadas en criterios
  Future<List<MarketplaceListing>> getRecommendedListings({
    required double latitude,
    required double longitude,
    double? budget,
    String? preferredType,
    List<String>? amenities,
    double radius = 3000,
  }) async {
    try {
      List<MarketplaceListing> listings = await searchMarketplaceListings(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        limit: 100,
      );

      // Filtrar por presupuesto
      if (budget != null) {
        listings = listings.where((listing) {
          if (listing.priceRange == null) return true;
          return listing.priceRange! <= budget * 1.1; // 10% de flexibilidad
        }).toList();
      }

      // Filtrar por tipo preferido
      if (preferredType != null) {
        listings = listings.where((listing) {
          final name = listing.name.toLowerCase();
          final description = listing.description?.toLowerCase() ?? '';
          return name.contains(preferredType.toLowerCase()) ||
                 description.contains(preferredType.toLowerCase());
        }).toList();
      }

      // Ordenar por precio (ascendente)
      listings.sort((a, b) {
        if (a.priceRange == null && b.priceRange == null) return 0;
        if (a.priceRange == null) return 1;
        if (b.priceRange == null) return -1;
        return a.priceRange!.compareTo(b.priceRange!);
      });

      return listings.take(20).toList();
    } catch (e) {
      print('Error obteniendo propiedades recomendadas: $e');
      return [];
    }
  }
}

class MarketplaceListing {
  final String id;
  final String name;
  final String? description;
  final String? link;
  final String? picture;
  final double? priceRange;
  final MarketplaceLocation? location;

  MarketplaceListing({
    required this.id,
    required this.name,
    this.description,
    this.link,
    this.picture,
    this.priceRange,
    this.location,
  });

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) {
    final locationData = json['location'];
    
    return MarketplaceListing(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      link: json['link'],
      picture: json['picture']?['data']?['url'],
      priceRange: json['price_range']?.toDouble(),
      location: locationData != null ? MarketplaceLocation.fromJson(locationData) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'link': link,
      'picture': picture,
      'priceRange': priceRange,
      'location': location?.toJson(),
    };
  }

  @override
  String toString() {
    return 'MarketplaceListing(id: $id, name: $name, priceRange: $priceRange)';
  }
}

class MarketplaceLocation {
  final double? latitude;
  final double? longitude;
  final String? street;
  final String? city;
  final String? country;

  MarketplaceLocation({
    this.latitude,
    this.longitude,
    this.street,
    this.city,
    this.country,
  });

  factory MarketplaceLocation.fromJson(Map<String, dynamic> json) {
    return MarketplaceLocation(
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      street: json['street'],
      city: json['city'],
      country: json['country'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'street': street,
      'city': city,
      'country': country,
    };
  }
}
