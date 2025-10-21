import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/marketplace_listing.dart';

class GooglePlacesMarketplaceService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';
  String? _apiKey;

  GooglePlacesMarketplaceService() {
    _apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
  }

  /// Buscar propiedades en renta usando Google Places API
  static Future<List<MarketplaceListing>> searchProperties({
    required double latitude,
    required double longitude,
    double radius = 5000, // metros
    String type = 'lodging', // tipos: lodging, real_estate_agency, etc.
    String keyword = 'renta departamento casa',
    int limit = 20,
  }) async {
    try {
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        print('❌ Google Places API Key no configurada');
        return [];
      }

      final url = '$_baseUrl/nearbysearch/json';
      final params = {
        'location': '$latitude,$longitude',
        'radius': radius.toString(),
        'type': type,
        'keyword': keyword,
        'key': apiKey,
      };

      print('🔍 Buscando propiedades con Google Places API...');
      print('📍 Ubicación: $latitude, $longitude');
      print('🔍 Tipo: $type');
      print('🔍 Palabra clave: $keyword');

      final uri = Uri.parse(url).replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] == 'OK' || data['status'] == 'ZERO_RESULTS') {
          final results = data['results'] as List;
          print('✅ Google Places API devolvió: ${results.length} resultados');
          
          final listings = <MarketplaceListing>[];
          
          for (int i = 0; i < results.length && i < limit; i++) {
            final place = results[i];
            final listing = await _convertPlaceToMarketplaceListing(place, i);
            if (listing != null) {
              listings.add(listing);
            }
          }
          
          return listings;
        } else {
          print('❌ Error Google Places API: ${data['status']}');
          return [];
        }
      } else {
        print('❌ Error HTTP Google Places: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error en Google Places API: $e');
      return [];
    }
  }

  /// Buscar agencias inmobiliarias
  static Future<List<MarketplaceListing>> searchRealEstateAgencies({
    required double latitude,
    required double longitude,
    double radius = 5000,
    int limit = 15,
  }) async {
    return await searchProperties(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      type: 'real_estate_agency',
      keyword: 'renta venta inmobiliaria',
      limit: limit,
    );
  }

  /// Buscar hoteles y hospedaje (que pueden tener rentas)
  static Future<List<MarketplaceListing>> searchLodging({
    required double latitude,
    required double longitude,
    double radius = 5000,
    int limit = 15,
  }) async {
    return await searchProperties(
      latitude: latitude,
      longitude: longitude,
      radius: radius,
      type: 'lodging',
      keyword: 'renta mensual departamento',
      limit: limit,
    );
  }

  /// Buscar establecimientos generales con filtros
  static Future<List<MarketplaceListing>> searchWithFilters({
    required double latitude,
    required double longitude,
    double radius = 5000,
    String type = 'establishment',
    List<String> keywords = const ['renta', 'departamento', 'casa', 'inmueble'],
    int minPrice = 5000,
    int maxPrice = 20000,
    int limit = 20,
  }) async {
    try {
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        print('❌ Google Places API Key no configurada');
        return [];
      }

      final allListings = <MarketplaceListing>[];
      
      // Buscar con cada palabra clave
      for (final keyword in keywords) {
        final url = '$_baseUrl/nearbysearch/json';
        final params = {
          'location': '$latitude,$longitude',
          'radius': radius.toString(),
          'type': type,
          'keyword': keyword,
          'key': apiKey,
        };

        final uri = Uri.parse(url).replace(queryParameters: params);
        final response = await http.get(uri);

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          
          if (data['status'] == 'OK') {
            final results = data['results'] as List;
            print('✅ Encontrados ${results.length} resultados para "$keyword"');
            
            for (final place in results) {
              final listing = await _convertPlaceToMarketplaceListing(place, allListings.length);
              if (listing != null && 
                  listing.price >= minPrice && 
                  listing.price <= maxPrice) {
                allListings.add(listing);
              }
            }
          }
        }
        
        // Evitar rate limiting
        await Future.delayed(const Duration(milliseconds: 200));
      }
      
      // Eliminar duplicados y limitar resultados
      final uniqueListings = <String, MarketplaceListing>{};
      for (final listing in allListings) {
        if (!uniqueListings.containsKey(listing.id)) {
          uniqueListings[listing.id] = listing;
        }
      }
      
      final finalListings = uniqueListings.values.take(limit).toList();
      print('✅ Propiedades filtradas encontradas: ${finalListings.length}');
      
      return finalListings;
      
    } catch (e) {
      print('❌ Error en búsqueda con filtros: $e');
      return [];
    }
  }

  /// Convertir un lugar de Google Places a MarketplaceListing
  static Future<MarketplaceListing?> _convertPlaceToMarketplaceListing(
    Map<String, dynamic> place, 
    int index,
  ) async {
    try {
      final name = place['name'] ?? 'Propiedad en renta';
      final rating = place['rating']?.toDouble() ?? 4.0;
      final priceLevel = place['price_level'] ?? 2;
      final types = List<String>.from(place['types'] ?? []);
      
      // Determinar precio basado en rating y price_level
      double basePrice = 8000.0;
      if (priceLevel == 1) basePrice = 6000.0;
      if (priceLevel == 2) basePrice = 8000.0;
      if (priceLevel == 3) basePrice = 12000.0;
      if (priceLevel == 4) basePrice = 18000.0;
      
      // Ajustar precio basado en rating
      final adjustedPrice = basePrice * (rating / 4.0);
      
      // Determinar categoría basada en tipos
      String category = 'Departamento';
      if (types.contains('real_estate_agency')) {
        category = 'Inmobiliaria';
      } else if (types.contains('lodging')) {
        category = 'Hospedaje';
      } else if (name.toLowerCase().contains('casa')) {
        category = 'Casa';
      } else if (name.toLowerCase().contains('estudio')) {
        category = 'Estudio';
      }
      
      // Obtener ubicación
      final geometry = place['geometry'];
      final location = geometry?['location'];
      final lat = location?['lat']?.toDouble() ?? 20.6597;
      final lng = location?['lng']?.toDouble() ?? -103.3496;
      
      // Obtener dirección
      final vicinity = place['vicinity'] ?? 'Guadalajara, Jalisco';
      
      // Obtener imagen real de Google Places si está disponible
      String imageUrl = '';
      final photos = place['photos'] as List?;
      if (photos != null && photos.isNotEmpty) {
        // Usar la primera foto disponible
        final photoRef = photos[0]['photo_reference'];
        final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
        if (photoRef != null && apiKey != null) {
          imageUrl = 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=$apiKey';
        }
      }
      
      return MarketplaceListing(
        id: 'google_places_${place['place_id'] ?? index}',
        title: name,
        description: 'Propiedad encontrada a través de Google Places. ${types.isNotEmpty ? 'Tipo: ${types.join(', ')}' : ''}',
        price: adjustedPrice,
        location: vicinity,
        latitude: lat,
        longitude: lng,
        imageUrl: imageUrl,
        category: category,
      );
      
    } catch (e) {
      print('❌ Error convirtiendo lugar: $e');
      return null;
    }
  }

  /// Obtener detalles adicionales de un lugar
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    try {
      final apiKey = dotenv.env['GOOGLE_PLACES_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) return null;

      final url = '$_baseUrl/details/json';
      final params = {
        'place_id': placeId,
        'fields': 'name,formatted_address,formatted_phone_number,website,rating,reviews,photos',
        'key': apiKey,
      };

      final uri = Uri.parse(url).replace(queryParameters: params);
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          return data['result'];
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error obteniendo detalles del lugar: $e');
      return null;
    }
  }

  /// Buscar propiedades con múltiples tipos y filtros
  static Future<List<MarketplaceListing>> searchComprehensive({
    required double latitude,
    required double longitude,
    double radius = 5000,
    int limit = 20,
  }) async {
    print('🔍 Búsqueda comprehensiva de propiedades...');
    
    final allListings = <MarketplaceListing>[];
    
    // Buscar en diferentes categorías
    final searchTypes = [
      {'type': 'real_estate_agency', 'keyword': 'renta venta inmobiliaria'},
      {'type': 'lodging', 'keyword': 'renta mensual departamento'},
      {'type': 'establishment', 'keyword': 'renta casa departamento'},
      {'type': 'establishment', 'keyword': 'inmueble renta'},
    ];
    
    for (final searchType in searchTypes) {
      try {
        final listings = await searchProperties(
          latitude: latitude,
          longitude: longitude,
          radius: radius,
          type: searchType['type']!,
          keyword: searchType['keyword']!,
          limit: limit ~/ searchTypes.length,
        );
        
        allListings.addAll(listings);
        
        // Delay para evitar rate limiting
        await Future.delayed(const Duration(milliseconds: 300));
        
      } catch (e) {
        print('❌ Error en búsqueda ${searchType['type']}: $e');
      }
    }
    
    // Eliminar duplicados basado en place_id
    final uniqueListings = <String, MarketplaceListing>{};
    for (final listing in allListings) {
      final key = listing.id.replaceAll('google_places_', '');
      if (!uniqueListings.containsKey(key)) {
        uniqueListings[key] = listing;
      }
    }
    
    final finalListings = uniqueListings.values.take(limit).toList();
    print('✅ Búsqueda comprehensiva completada: ${finalListings.length} propiedades únicas');
    
    return finalListings;
  }
}
