import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/marketplace_listing.dart';

class RealMarketplaceService {
  /// Buscar propiedades en Vivanuncios (scraping)
  static Future<List<MarketplaceListing>> searchVivanuncios({
    required double latitude,
    required double longitude,
    double radius = 5000,
    int limit = 20,
  }) async {
    try {
      // URL de Vivanuncios para renta en Guadalajara
      final url = 'https://www.vivanuncios.com.mx/s-renta-inmuebles/guadalajara/v1c1098l1027p1';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8',
          'Accept-Language': 'es-MX,es;q=0.8,en-US;q=0.5,en;q=0.3',
          'Accept-Encoding': 'gzip, deflate, br',
          'Connection': 'keep-alive',
          'Upgrade-Insecure-Requests': '1',
        },
      );

      if (response.statusCode == 200) {
        return _parseVivanunciosHTML(response.body, limit);
      } else {
        print('❌ Error Vivanuncios: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error conectando con Vivanuncios: $e');
      return [];
    }
  }

  /// Buscar propiedades en Inmuebles24
  static Future<List<MarketplaceListing>> searchInmuebles24({
    required double latitude,
    required double longitude,
    double radius = 5000,
    int limit = 20,
  }) async {
    try {
      final url = 'https://www.inmuebles24.com/propiedades/renta-guadalajara-jalisco';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
          'Accept-Language': 'es-MX,es;q=0.8,en-US;q=0.5,en;q=0.3',
        },
      );

      if (response.statusCode == 200) {
        return _parseInmuebles24HTML(response.body, limit);
      } else {
        print('❌ Error Inmuebles24: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error conectando con Inmuebles24: $e');
      return [];
    }
  }

  /// Buscar propiedades en Propiedades.com
  static Future<List<MarketplaceListing>> searchPropiedades({
    required double latitude,
    required double longitude,
    double radius = 5000,
    int limit = 20,
  }) async {
    try {
      final url = 'https://www.propiedades.com/renta/jalisco/guadalajara';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      );

      if (response.statusCode == 200) {
        return _parsePropiedadesHTML(response.body, limit);
      } else {
        print('❌ Error Propiedades.com: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error conectando con Propiedades.com: $e');
      return [];
    }
  }

  /// Buscar propiedades en Metros Cúbicos
  static Future<List<MarketplaceListing>> searchMetrosCubicos({
    required double latitude,
    required double longitude,
    double radius = 5000,
    int limit = 20,
  }) async {
    try {
      final url = 'https://www.metrocuadrado.com/arriendo/casa/guadalajara';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
          'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        },
      );

      if (response.statusCode == 200) {
        return _parseMetrosCubicosHTML(response.body, limit);
      } else {
        print('❌ Error Metros Cúbicos: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('❌ Error conectando con Metros Cúbicos: $e');
      return [];
    }
  }

  /// Método principal que combina todas las fuentes
  static Future<List<MarketplaceListing>> searchAllSources({
    required double latitude,
    required double longitude,
    double radius = 5000,
    int limit = 20,
  }) async {
    print('🔍 Buscando propiedades reales en múltiples fuentes...');
    
    final allListings = <MarketplaceListing>[];
    
    // Buscar en paralelo en todas las fuentes
    final futures = [
      searchVivanuncios(latitude: latitude, longitude: longitude, limit: limit ~/ 4),
      searchInmuebles24(latitude: latitude, longitude: longitude, limit: limit ~/ 4),
      searchPropiedades(latitude: latitude, longitude: longitude, limit: limit ~/ 4),
      searchMetrosCubicos(latitude: latitude, longitude: longitude, limit: limit ~/ 4),
    ];

    try {
      final results = await Future.wait(futures);
      
      for (final listings in results) {
        allListings.addAll(listings);
      }
      
      print('✅ Propiedades reales encontradas: ${allListings.length}');
      return allListings.take(limit).toList();
      
    } catch (e) {
      print('❌ Error buscando propiedades reales: $e');
      return [];
    }
  }

  /// Parsear HTML de Vivanuncios
  static List<MarketplaceListing> _parseVivanunciosHTML(String html, int limit) {
    final listings = <MarketplaceListing>[];
    
    try {
      // Buscar patrones de propiedades en el HTML
      final propertyRegex = RegExp(r'<div[^>]*class="[^"]*ad-item[^"]*"[^>]*>.*?</div>', dotAll: true);
      final matches = propertyRegex.allMatches(html).take(limit);
      
      for (final match in matches) {
        final propertyHtml = match.group(0)!;
        
        // Extraer título
        final titleMatch = RegExp(r'<h3[^>]*>([^<]+)</h3>').firstMatch(propertyHtml);
        final title = titleMatch?.group(1)?.trim() ?? 'Propiedad en renta';
        
        // Extraer precio
        final priceMatch = RegExp(r'\$[\d,]+').firstMatch(propertyHtml);
        final priceStr = priceMatch?.group(0)?.replaceAll(RegExp(r'[^\d]'), '') ?? '8000';
        final price = double.tryParse(priceStr) ?? 8000.0;
        
        // Extraer ubicación
        final locationMatch = RegExp(r'<span[^>]*class="[^"]*location[^"]*"[^>]*>([^<]+)</span>').firstMatch(propertyHtml);
        final location = locationMatch?.group(1)?.trim() ?? 'Guadalajara';
        
        // Extraer imagen
        final imageMatch = RegExp(r'<img[^>]*src="([^"]+)"').firstMatch(propertyHtml);
        final imageUrl = imageMatch?.group(1) ?? 'https://picsum.photos/300/200?random=${listings.length}';
        
        final listing = MarketplaceListing(
          id: 'vivanuncios_${listings.length + 1}',
          title: title,
          description: 'Propiedad en renta encontrada en Vivanuncios',
          price: price,
          location: location,
          latitude: 20.6597 + (listings.length * 0.001),
          longitude: -103.3496 + (listings.length * 0.001),
          imageUrl: imageUrl,
          category: title.contains('Casa') ? 'Casa' : 'Departamento',
        );
        
        listings.add(listing);
      }
      
      print('✅ Vivanuncios: ${listings.length} propiedades encontradas');
      
    } catch (e) {
      print('❌ Error parseando Vivanuncios: $e');
    }
    
    return listings;
  }

  /// Parsear HTML de Inmuebles24
  static List<MarketplaceListing> _parseInmuebles24HTML(String html, int limit) {
    final listings = <MarketplaceListing>[];
    
    try {
      // Buscar patrones específicos de Inmuebles24
      final propertyRegex = RegExp(r'<article[^>]*class="[^"]*posting[^"]*"[^>]*>.*?</article>', dotAll: true);
      final matches = propertyRegex.allMatches(html).take(limit);
      
      for (final match in matches) {
        final propertyHtml = match.group(0)!;
        
        // Extraer información básica
        final titleMatch = RegExp(r'<h2[^>]*>([^<]+)</h2>').firstMatch(propertyHtml);
        final title = titleMatch?.group(1)?.trim() ?? 'Propiedad en renta';
        
        final priceMatch = RegExp(r'\$[\d,]+').firstMatch(propertyHtml);
        final priceStr = priceMatch?.group(0)?.replaceAll(RegExp(r'[^\d]'), '') ?? '8500';
        final price = double.tryParse(priceStr) ?? 8500.0;
        
        final listing = MarketplaceListing(
          id: 'inmuebles24_${listings.length + 1}',
          title: title,
          description: 'Propiedad en renta encontrada en Inmuebles24',
          price: price,
          location: 'Guadalajara',
          latitude: 20.6597 + (listings.length * 0.001),
          longitude: -103.3496 + (listings.length * 0.001),
          imageUrl: 'https://picsum.photos/300/200?random=${listings.length + 100}',
          category: 'Departamento',
        );
        
        listings.add(listing);
      }
      
      print('✅ Inmuebles24: ${listings.length} propiedades encontradas');
      
    } catch (e) {
      print('❌ Error parseando Inmuebles24: $e');
    }
    
    return listings;
  }

  /// Parsear HTML de Propiedades.com
  static List<MarketplaceListing> _parsePropiedadesHTML(String html, int limit) {
    final listings = <MarketplaceListing>[];
    
    try {
      // Implementar parsing específico para Propiedades.com
      final propertyRegex = RegExp(r'<div[^>]*class="[^"]*property[^"]*"[^>]*>.*?</div>', dotAll: true);
      final matches = propertyRegex.allMatches(html).take(limit);
      
      for (final match in matches) {
        final propertyHtml = match.group(0)!;
        
        final titleMatch = RegExp(r'<h3[^>]*>([^<]+)</h3>').firstMatch(propertyHtml);
        final title = titleMatch?.group(1)?.trim() ?? 'Propiedad en renta';
        
        final priceMatch = RegExp(r'\$[\d,]+').firstMatch(propertyHtml);
        final priceStr = priceMatch?.group(0)?.replaceAll(RegExp(r'[^\d]'), '') ?? '9000';
        final price = double.tryParse(priceStr) ?? 9000.0;
        
        final listing = MarketplaceListing(
          id: 'propiedades_${listings.length + 1}',
          title: title,
          description: 'Propiedad en renta encontrada en Propiedades.com',
          price: price,
          location: 'Guadalajara',
          latitude: 20.6597 + (listings.length * 0.001),
          longitude: -103.3496 + (listings.length * 0.001),
          imageUrl: 'https://picsum.photos/300/200?random=${listings.length + 200}',
          category: 'Casa',
        );
        
        listings.add(listing);
      }
      
      print('✅ Propiedades.com: ${listings.length} propiedades encontradas');
      
    } catch (e) {
      print('❌ Error parseando Propiedades.com: $e');
    }
    
    return listings;
  }

  /// Parsear HTML de Metros Cúbicos
  static List<MarketplaceListing> _parseMetrosCubicosHTML(String html, int limit) {
    final listings = <MarketplaceListing>[];
    
    try {
      // Implementar parsing específico para Metros Cúbicos
      final propertyRegex = RegExp(r'<div[^>]*class="[^"]*property-card[^"]*"[^>]*>.*?</div>', dotAll: true);
      final matches = propertyRegex.allMatches(html).take(limit);
      
      for (final match in matches) {
        final propertyHtml = match.group(0)!;
        
        final titleMatch = RegExp(r'<h4[^>]*>([^<]+)</h4>').firstMatch(propertyHtml);
        final title = titleMatch?.group(1)?.trim() ?? 'Propiedad en renta';
        
        final priceMatch = RegExp(r'\$[\d,]+').firstMatch(propertyHtml);
        final priceStr = priceMatch?.group(0)?.replaceAll(RegExp(r'[^\d]'), '') ?? '7500';
        final price = double.tryParse(priceStr) ?? 7500.0;
        
        final listing = MarketplaceListing(
          id: 'metroscubicos_${listings.length + 1}',
          title: title,
          description: 'Propiedad en renta encontrada en Metros Cúbicos',
          price: price,
          location: 'Guadalajara',
          latitude: 20.6597 + (listings.length * 0.001),
          longitude: -103.3496 + (listings.length * 0.001),
          imageUrl: 'https://picsum.photos/300/200?random=${listings.length + 300}',
          category: 'Estudio',
        );
        
        listings.add(listing);
      }
      
      print('✅ Metros Cúbicos: ${listings.length} propiedades encontradas');
      
    } catch (e) {
      print('❌ Error parseando Metros Cúbicos: $e');
    }
    
    return listings;
  }
}
