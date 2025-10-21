import 'package:flutter/material.dart';
import '../models/marketplace_listing.dart';

class MarketplaceMockService {
  /// Generar datos mock de Marketplace para demostración
  static Future<List<MarketplaceListing>> getMockListings({
    required double latitude,
    required double longitude,
    double radius = 5000,
    int limit = 20,
  }) async {
    // Simular delay de API
    await Future.delayed(const Duration(seconds: 1));

    final listings = <MarketplaceListing>[];
    
    // Generar datos mock alrededor de la ubicación
    final basePrice = 8000.0;
    final categories = ['Departamento', 'Casa', 'Estudio', 'Penthouse'];
    final locations = [
      'Centro Histórico',
      'Zona Rosa',
      'Chapalita',
      'Providencia',
      'Americana',
      'Lafayette',
      'Lomas del Valle',
      'Jardines del Bosque',
    ];

    for (int i = 0; i < limit; i++) {
      // Generar coordenadas aleatorias cerca de la ubicación
      final offsetLat = (i % 4 - 2) * 0.01; // ±0.02 grados
      final offsetLon = (i % 3 - 1) * 0.01;
      
      final listing = MarketplaceListing(
        id: 'marketplace_${i + 1}',
        title: '${categories[i % categories.length]} en ${locations[i % locations.length]}',
        description: 'Hermoso ${categories[i % categories.length].toLowerCase()} con excelente ubicación, cerca de transporte público y servicios.',
        price: basePrice + (i * 500),
        location: locations[i % locations.length],
        latitude: latitude + offsetLat,
        longitude: longitude + offsetLon,
        imageUrl: 'https://picsum.photos/300/200?random=${i + 1}',
        category: categories[i % categories.length],
      );
      
      listings.add(listing);
    }

    return listings;
  }

  /// Obtener estadísticas de Marketplace
  static Map<String, dynamic> getMarketplaceStats(List<MarketplaceListing> listings) {
    if (listings.isEmpty) {
      return {
        'total': 0,
        'averagePrice': 0.0,
        'priceRange': {'min': 0.0, 'max': 0.0},
        'categories': <String, int>{},
      };
    }

    final prices = listings.map((l) => l.price).toList();
    final categories = <String, int>{};

    for (final listing in listings) {
      categories[listing.category] = (categories[listing.category] ?? 0) + 1;
    }

    return {
      'total': listings.length,
      'averagePrice': prices.reduce((a, b) => a + b) / prices.length,
      'priceRange': {
        'min': prices.reduce((a, b) => a < b ? a : b),
        'max': prices.reduce((a, b) => a > b ? a : b),
      },
      'categories': categories,
    };
  }
}
