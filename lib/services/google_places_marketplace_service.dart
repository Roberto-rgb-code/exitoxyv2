import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/marketplace_listing.dart';
import '../core/config.dart';

class GooglePlacesMarketplaceService {
  static const String _baseUrl = 'https://maps.googleapis.com/maps/api/place';

  /// Verifica si la API de Google Places está configurada correctamente
  static bool get isConfigured {
    return Config.hasValidGooglePlacesKey;
  }

  /// Buscar propiedades en renta usando Google Places API
  static Future<List<MarketplaceListing>> searchProperties({
    required double latitude,
    required double longitude,
    double radius = 5000,
    String type = 'real_estate_agency',
    String keyword = 'renta departamento casa inmobiliaria',
    int limit = 20,
  }) async {
    // Verificar si la API está configurada
    if (!isConfigured) {
      print('⚠️ Google Places API Key NO configurada');
      print('   Para habilitar propiedades, configura GOOGLE_PLACES_API_KEY en .env');
      return [];
    }

    try {
      final apiKey = Config.googlePlacesApiKey;
      
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
      print('🔍 Tipo: $type, Keyword: $keyword');

      final uri = Uri.parse(url).replace(queryParameters: params);
      final response = await http.get(uri).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Timeout conectando con Google Places API');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final status = data['status'];
        
        print('📊 Google Places Status: $status');
        
        if (status == 'OK') {
          final results = data['results'] as List;
          print('✅ Google Places: ${results.length} resultados');
          
          final listings = <MarketplaceListing>[];
          
          for (int i = 0; i < results.length && i < limit; i++) {
            final place = results[i];
            final listing = _convertPlaceToListing(place, i);
            if (listing != null) {
              listings.add(listing);
            }
          }
          
          return listings;
        } else if (status == 'ZERO_RESULTS') {
          print('ℹ️ Google Places: Sin resultados en esta zona');
          return [];
        } else if (status == 'REQUEST_DENIED') {
          print('❌ Google Places: API Key inválida o sin permisos');
          print('   Verifica que la API Key tenga habilitado Places API');
          return [];
        } else if (status == 'OVER_QUERY_LIMIT') {
          print('❌ Google Places: Límite de consultas excedido');
          return [];
        } else {
          print('❌ Google Places error: $status');
          if (data['error_message'] != null) {
            print('   Mensaje: ${data['error_message']}');
          }
          return [];
        }
      } else {
        print('❌ HTTP Error: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error Google Places: $e');
      return [];
    }
  }

  /// Búsqueda comprehensiva de propiedades
  static Future<List<MarketplaceListing>> searchComprehensive({
    required double latitude,
    required double longitude,
    double radius = 5000,
    int limit = 20,
  }) async {
    if (!isConfigured) {
      print('⚠️ Google Places API no configurada - Propiedades deshabilitadas');
      return [];
    }

    print('🏠 Búsqueda comprehensiva de propiedades...');
    
    final allListings = <MarketplaceListing>[];
    
    // Búsquedas con diferentes tipos
    final searches = [
      {'type': 'real_estate_agency', 'keyword': 'inmobiliaria renta venta'},
      {'type': 'lodging', 'keyword': 'departamento renta'},
    ];
    
    for (final search in searches) {
      try {
        final listings = await searchProperties(
          latitude: latitude,
          longitude: longitude,
          radius: radius,
          type: search['type']!,
          keyword: search['keyword']!,
          limit: limit ~/ searches.length,
        );
        allListings.addAll(listings);
        
        // Pequeño delay para no saturar la API
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        print('⚠️ Error en búsqueda ${search['type']}: $e');
      }
    }
    
    // Eliminar duplicados
    final uniqueIds = <String>{};
    final uniqueListings = allListings.where((listing) {
      if (uniqueIds.contains(listing.id)) return false;
      uniqueIds.add(listing.id);
      return true;
    }).take(limit).toList();
    
    print('✅ Total propiedades únicas: ${uniqueListings.length}');
    return uniqueListings;
  }

  /// Convertir lugar de Google Places a MarketplaceListing
  static MarketplaceListing? _convertPlaceToListing(
    Map<String, dynamic> place,
    int index,
  ) {
    try {
      final name = place['name'] ?? 'Propiedad';
      final placeId = place['place_id'] ?? 'unknown_$index';
      final rating = (place['rating'] ?? 4.0).toDouble();
      final priceLevel = place['price_level'] ?? 2;
      final types = List<String>.from(place['types'] ?? []);
      
      // Determinar precio estimado
      double price = 8000.0;
      if (priceLevel == 1) price = 5000.0;
      if (priceLevel == 2) price = 8000.0;
      if (priceLevel == 3) price = 15000.0;
      if (priceLevel == 4) price = 25000.0;
      price = price * (rating / 4.0);
      
      // Determinar categoría
      String category = 'Propiedad';
      if (types.contains('real_estate_agency')) {
        category = 'Inmobiliaria';
      } else if (types.contains('lodging')) {
        category = 'Hospedaje';
      }
      
      // Ubicación
      final geometry = place['geometry'];
      final location = geometry?['location'];
      final lat = (location?['lat'] ?? 20.6597).toDouble();
      final lng = (location?['lng'] ?? -103.3496).toDouble();
      
      final vicinity = place['vicinity'] ?? 'Guadalajara, Jalisco';
      
      // Imagen si está disponible
      String imageUrl = '';
      final photos = place['photos'] as List?;
      if (photos != null && photos.isNotEmpty) {
        final photoRef = photos[0]['photo_reference'];
        if (photoRef != null && Config.hasValidGooglePlacesKey) {
          imageUrl = 'https://maps.googleapis.com/maps/api/place/photo?maxwidth=400&photoreference=$photoRef&key=${Config.googlePlacesApiKey}';
        }
      }
      
      return MarketplaceListing(
        id: 'gp_$placeId',
        title: name,
        description: 'Encontrado via Google Places. Rating: ${rating.toStringAsFixed(1)}⭐',
        price: price,
        location: vicinity,
        latitude: lat,
        longitude: lng,
        imageUrl: imageUrl,
        category: category,
      );
    } catch (e) {
      print('⚠️ Error convirtiendo lugar: $e');
      return null;
    }
  }

  /// Obtener detalles de un lugar
  static Future<Map<String, dynamic>?> getPlaceDetails(String placeId) async {
    if (!isConfigured) return null;

    try {
      final url = '$_baseUrl/details/json';
      final params = {
        'place_id': placeId,
        'fields': 'name,formatted_address,formatted_phone_number,website,rating,photos',
        'key': Config.googlePlacesApiKey,
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
      print('❌ Error obteniendo detalles: $e');
      return null;
    }
  }
}
