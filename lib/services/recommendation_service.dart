import '../models/delito_model.dart';
import '../models/search_record_model.dart';
import '../models/recommendation.dart';
import '../services/delitos_service.dart';
import '../services/google_places_service.dart';
import '../services/search_history_service.dart';

class RecommendationService {
  final DelitosService _delitosService = DelitosService();
  final GooglePlacesService _placesService = GooglePlacesService();
  final SearchHistoryService _searchService = SearchHistoryService();

  /// Generar recomendaciones de ubicaciones para renta
  Future<List<Recommendation>> generateRecommendations({
    required double latitude,
    required double longitude,
    required String locationName,
    Map<String, dynamic>? userPreferences,
  }) async {
    try {
      // Obtener datos de delitos en el área
      final delitos = _delitosService.getDelitosByLocation(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: 2000, // 2km de radio
      );

      // Obtener servicios cercanos
      final services = await _placesService.getEssentialServices(
        latitude: latitude,
        longitude: longitude,
        radius: 1000,
      );

      // Calcular score de seguridad
      final safetyScore = _calculateSafetyScore(delitos);

      // Calcular score de servicios
      final servicesScore = _calculateServicesScore(services);

      // Calcular score de transporte
      final transportScore = _calculateTransportScore(services['transit_station'] ?? []);

      // Calcular score general
      final overallScore = _calculateOverallScore(
        safetyScore: safetyScore,
        servicesScore: servicesScore,
        transportScore: transportScore,
      );

      // Crear recomendación como Map
      final recommendation = Recommendation(
        locationName: locationName,
        latitude: latitude,
        longitude: longitude,
        score: overallScore,
        factors: {
          'safety': safetyScore,
          'services': servicesScore,
          'transport': transportScore,
        },
        description: _generateRecommendationsText(
          safetyScore: safetyScore,
          servicesScore: servicesScore,
          transportScore: transportScore,
          crimeCount: delitos.length,
        ).join('\n'),
        type: 'location',
        title: locationName,
        details: [
          'Seguridad: ${safetyScore.toStringAsFixed(1)}/100',
          'Servicios: ${servicesScore.toStringAsFixed(1)}/100',
          'Transporte: ${transportScore.toStringAsFixed(1)}/100',
          'Delitos en el área: ${delitos.length}',
        ],
      );

      // Intentar guardar búsqueda en historial (opcional, no crítico)
      try {
        await _searchService.saveSearch(
          latitude: latitude,
          longitude: longitude,
          locationName: locationName,
          searchFilters: userPreferences,
          crimeData: {
            'count': delitos.length,
            'types': _getCrimeTypes(delitos),
            'safetyScore': safetyScore,
          },
          placesData: _getNearbyServices(services),
        );
      } catch (e) {
        print('⚠️ No se pudo guardar en historial (opcional): $e');
        // Continuar sin fallar
      }

      return [recommendation];
    } catch (e) {
      print('Error generando recomendaciones: $e');
      return [];
    }
  }

  /// Calcular score de seguridad (0-100)
  double _calculateSafetyScore(List<DelitoModel> delitos) {
    if (delitos.isEmpty) return 100.0;

    // Penalizar por cantidad de delitos
    double score = 100.0;
    
    // Reducir score por cada delito
    score -= (delitos.length * 2).clamp(0.0, 50.0);
    
    // Penalizar más por delitos violentos
    final violentCrimes = delitos.where((d) => 
      d.delito.toLowerCase().contains('homicidio') ||
      d.delito.toLowerCase().contains('violencia')
    ).length;
    
    score -= (violentCrimes * 10).clamp(0.0, 30.0);
    
    // Penalizar por delitos recientes (últimos 6 meses)
    final recentCrimes = delitos.where((d) {
      try {
        final crimeDate = DateTime.parse(d.fecha);
        final sixMonthsAgo = DateTime.now().subtract(const Duration(days: 180));
        return crimeDate.isAfter(sixMonthsAgo);
      } catch (e) {
        return false;
      }
    }).length;
    
    score -= (recentCrimes * 5).clamp(0.0, 20.0);
    
    return score.clamp(0.0, 100.0);
  }

  /// Calcular score de servicios (0-100)
  double _calculateServicesScore(Map<String, List<PlaceResult>> services) {
    double score = 0.0;
    
    // Hospitales (peso: 25%)
    final hospitals = services['hospital'] ?? [];
    score += (hospitals.length * 5).clamp(0.0, 25.0);
    
    // Escuelas (peso: 20%)
    final schools = services['school'] ?? [];
    score += (schools.length * 4).clamp(0.0, 20.0);
    
    // Farmacias (peso: 15%)
    final pharmacies = services['pharmacy'] ?? [];
    score += (pharmacies.length * 3).clamp(0.0, 15.0);
    
    // Gasolineras (peso: 10%)
    final gasStations = services['gas_station'] ?? [];
    score += (gasStations.length * 2).clamp(0.0, 10.0);
    
    // Policía (peso: 15%)
    final police = services['police'] ?? [];
    score += (police.length * 3).clamp(0.0, 15.0);
    
    // Bomberos (peso: 15%)
    final fireStations = services['fire_station'] ?? [];
    score += (fireStations.length * 3).clamp(0.0, 15.0);
    
    return score.clamp(0.0, 100.0);
  }

  /// Calcular score de transporte (0-100)
  double _calculateTransportScore(List<PlaceResult> transitStations) {
    if (transitStations.isEmpty) return 0.0;
    
    // Score basado en cantidad de estaciones de transporte
    double score = (transitStations.length * 20).toDouble().clamp(0.0, 100.0);
    
    // Bonus por estaciones con buena calificación
    final avgRating = transitStations
        .map((s) => s.rating)
        .reduce((a, b) => a + b) / transitStations.length;
    
    if (avgRating > 4.0) score += 20.0;
    else if (avgRating > 3.5) score += 10.0;
    
    return score.clamp(0.0, 100.0);
  }

  /// Calcular score general
  double _calculateOverallScore({
    required double safetyScore,
    required double servicesScore,
    required double transportScore,
  }) {
    // Pesos: Seguridad 50%, Servicios 30%, Transporte 20%
    return (safetyScore * 0.5 + servicesScore * 0.3 + transportScore * 0.2);
  }

  /// Obtener tipos de delitos únicos
  List<String> _getCrimeTypes(List<DelitoModel> delitos) {
    return delitos.map((d) => d.delito).toSet().toList();
  }

  /// Obtener servicios cercanos
  Map<String, int> _getNearbyServices(Map<String, List<PlaceResult>> services) {
    final Map<String, int> nearbyServices = {};
    
    services.forEach((key, value) {
      nearbyServices[key] = value.length;
    });
    
    return nearbyServices;
  }

  /// Generar texto de recomendaciones
  List<String> _generateRecommendationsText({
    required double safetyScore,
    required double servicesScore,
    required double transportScore,
    required int crimeCount,
  }) {
    final List<String> recommendations = [];
    
    // Recomendaciones de seguridad
    if (safetyScore < 50) {
      recommendations.add('⚠️ Alta incidencia delictiva. Considera otras ubicaciones.');
    } else if (safetyScore < 70) {
      recommendations.add('⚠️ Moderada incidencia delictiva. Toma precauciones adicionales.');
    } else {
      recommendations.add('✅ Zona relativamente segura.');
    }
    
    // Recomendaciones de servicios
    if (servicesScore < 30) {
      recommendations.add('📋 Servicios limitados. Verifica disponibilidad de servicios esenciales.');
    } else if (servicesScore < 60) {
      recommendations.add('📋 Servicios básicos disponibles.');
    } else {
      recommendations.add('✅ Excelente disponibilidad de servicios.');
    }
    
    // Recomendaciones de transporte
    if (transportScore < 30) {
      recommendations.add('🚌 Transporte limitado. Considera opciones de movilidad personal.');
    } else if (transportScore < 60) {
      recommendations.add('🚌 Transporte básico disponible.');
    } else {
      recommendations.add('✅ Excelente conectividad de transporte.');
    }
    
    // Recomendación general
    final overallScore = _calculateOverallScore(
      safetyScore: safetyScore,
      servicesScore: servicesScore,
      transportScore: transportScore,
    );
    
    if (overallScore >= 80) {
      recommendations.add('🌟 Excelente ubicación para renta.');
    } else if (overallScore >= 60) {
      recommendations.add('👍 Buena ubicación con algunas consideraciones.');
    } else {
      recommendations.add('⚠️ Revisa cuidadosamente antes de decidir.');
    }
    
    return recommendations;
  }

  /// Obtener recomendaciones basadas en historial del usuario
  Future<List<Recommendation>> getPersonalizedRecommendations({
    required double latitude,
    required double longitude,
  }) async {
    try {
      // Obtener historial de búsquedas del usuario
      final searchHistory = await _searchService.getUserSearchHistory();
      
      // Analizar patrones de búsqueda
      final preferredAreas = <String, int>{};
      for (final search in searchHistory) {
        final municipio = search.locationName.split(',').last.trim();
        preferredAreas[municipio] = (preferredAreas[municipio] ?? 0) + 1;
      }
      
      // Generar recomendaciones basadas en preferencias
      final recommendations = await generateRecommendations(
        latitude: latitude,
        longitude: longitude,
        locationName: 'Ubicación personalizada',
        userPreferences: {
          'preferredAreas': preferredAreas,
          'searchHistory': searchHistory.length,
        },
      );
      
      return recommendations;
    } catch (e) {
      print('Error obteniendo recomendaciones personalizadas: $e');
      return [];
    }
  }
}

class LocationRecommendation {
  final String locationName;
  final double latitude;
  final double longitude;
  final double safetyScore;
  final double servicesScore;
  final double transportScore;
  final double overallScore;
  final int crimeCount;
  final List<String> crimeTypes;
  final Map<String, int> nearbyServices;
  final List<String> recommendations;

  LocationRecommendation({
    required this.locationName,
    required this.latitude,
    required this.longitude,
    required this.safetyScore,
    required this.servicesScore,
    required this.transportScore,
    required this.overallScore,
    required this.crimeCount,
    required this.crimeTypes,
    required this.nearbyServices,
    required this.recommendations,
  });

  Map<String, dynamic> toJson() {
    return {
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'safetyScore': safetyScore,
      'servicesScore': servicesScore,
      'transportScore': transportScore,
      'overallScore': overallScore,
      'crimeCount': crimeCount,
      'crimeTypes': crimeTypes,
      'nearbyServices': nearbyServices,
      'recommendations': recommendations,
    };
  }

  factory LocationRecommendation.fromJson(Map<String, dynamic> json) {
    return LocationRecommendation(
      locationName: json['locationName'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      safetyScore: (json['safetyScore'] ?? 0.0).toDouble(),
      servicesScore: (json['servicesScore'] ?? 0.0).toDouble(),
      transportScore: (json['transportScore'] ?? 0.0).toDouble(),
      overallScore: (json['overallScore'] ?? 0.0).toDouble(),
      crimeCount: json['crimeCount'] ?? 0,
      crimeTypes: List<String>.from(json['crimeTypes'] ?? []),
      nearbyServices: Map<String, int>.from(json['nearbyServices'] ?? {}),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }
}