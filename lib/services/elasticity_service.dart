import 'dart:math' as math;

/// Resultado de análisis de elasticidad precio-espacial
class SpatialElasticityResult {
  final double density; // Negocios por km²
  final double competitionIndex; // Índice de competencia (0-1)
  final double elasticity; // Elasticidad precio-espacial estimada
  final Map<String, dynamic> details;

  SpatialElasticityResult({
    required this.density,
    required this.competitionIndex,
    required this.elasticity,
    required this.details,
  });
}

/// Resultado de análisis de elasticidad cruzada
class CrossElasticityResult {
  final String activity1;
  final String activity2;
  final double distance; // Distancia promedio entre negocios similares
  final double substitutionIndex; // Índice de sustitución (0-1)
  final double elasticity; // Elasticidad cruzada estimada

  CrossElasticityResult({
    required this.activity1,
    required this.activity2,
    required this.distance,
    required this.substitutionIndex,
    required this.elasticity,
  });
}

/// Resultado de análisis de elasticidad ingreso
class IncomeElasticityResult {
  final String activity;
  final double population;
  final double activePopulation; // PEA
  final double businessDensity;
  final double elasticity; // Elasticidad ingreso estimada
  final Map<String, dynamic> details;

  IncomeElasticityResult({
    required this.activity,
    required this.population,
    required this.activePopulation,
    required this.businessDensity,
    required this.elasticity,
    required this.details,
  });
}

class ElasticityService {
  /// Calcula distancia entre dos puntos en km (fórmula de Haversine)
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371.0; // km

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degrees) {
    return degrees * math.pi / 180.0;
  }

  /// Convierte un valor dinámico a double, manejando strings y nulls
  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
  }

  /// Calcula el área aproximada de un círculo dado el radio en km
  static double calculateArea(double radiusKm) {
    return math.pi * radiusKm * radiusKm;
  }

  /// Análisis de elasticidad precio-espacial
  /// Basado en densidad de negocios y concentración geográfica
  static SpatialElasticityResult analyzeSpatialPriceElasticity(
    List<Map<String, dynamic>> businesses,
    double radiusKm,
  ) {
    if (businesses.isEmpty) {
      return SpatialElasticityResult(
        density: 0.0,
        competitionIndex: 0.0,
        elasticity: 0.0,
        details: {},
      );
    }

    final area = calculateArea(radiusKm);
    final density = businesses.length / area; // negocios por km²

    // Calcular índice de competencia espacial
    // Basado en la distancia promedio entre negocios
    double totalDistance = 0.0;
    int comparisons = 0;

    for (int i = 0; i < businesses.length; i++) {
      final lat1 = _toDouble(businesses[i]['lat'] ?? 0.0);
      final lon1 = _toDouble(businesses[i]['lon'] ?? 0.0);

      for (int j = i + 1; j < businesses.length; j++) {
        final lat2 = _toDouble(businesses[j]['lat'] ?? 0.0);
        final lon2 = _toDouble(businesses[j]['lon'] ?? 0.0);

        final distance = calculateDistance(lat1, lon1, lat2, lon2);
        totalDistance += distance;
        comparisons++;
      }
    }

    final avgDistance = comparisons > 0 ? totalDistance / comparisons : 0.0;

    // Índice de competencia: más cercanos = más competencia
    // Normalizado: distancia < 1km = alta competencia (1.0), > 5km = baja (0.0)
    final competitionIndex = math.max(0.0, math.min(1.0, 1.0 - (avgDistance / 5.0)));

    // Elasticidad precio-espacial estimada
    // Mayor densidad y competencia → mayor elasticidad
    // Fórmula: E = -α * densidad * competencia
    // α es un factor de escala (normalizado)
    final elasticity = -(density / 100.0) * competitionIndex * 0.5;

    return SpatialElasticityResult(
      density: density,
      competitionIndex: competitionIndex,
      elasticity: elasticity,
      details: {
        'area_km2': area,
        'total_businesses': businesses.length,
        'avg_distance_km': avgDistance,
      },
    );
  }

  /// Análisis de elasticidad cruzada (sustitutos)
  /// Mide la proximidad entre negocios de actividades similares
  static List<CrossElasticityResult> analyzeCrossElasticity(
    List<Map<String, dynamic>> businesses,
  ) {
    final results = <CrossElasticityResult>[];

    // Agrupar por actividad económica
    final Map<String, List<Map<String, dynamic>>> byActivity = {};
    for (var business in businesses) {
      final activity = business['descripcion'] ?? business['codigo_actividad'] ?? 'Sin clasificar';
      if (!byActivity.containsKey(activity)) {
        byActivity[activity] = [];
      }
      byActivity[activity]!.add(business);
    }

    final activities = byActivity.keys.toList();

    // Comparar cada par de actividades
    for (int i = 0; i < activities.length; i++) {
      for (int j = i + 1; j < activities.length; j++) {
        final activity1 = activities[i];
        final activity2 = activities[j];

        final businesses1 = byActivity[activity1]!;
        final businesses2 = byActivity[activity2]!;

        // Calcular distancia promedio entre negocios de ambas actividades
        double totalDistance = 0.0;
        int comparisons = 0;

        for (var b1 in businesses1) {
          final lat1 = _toDouble(b1['lat'] ?? 0.0);
          final lon1 = _toDouble(b1['lon'] ?? 0.0);

          for (var b2 in businesses2) {
            final lat2 = _toDouble(b2['lat'] ?? 0.0);
            final lon2 = _toDouble(b2['lon'] ?? 0.0);

            final distance = calculateDistance(lat1, lon1, lat2, lon2);
            totalDistance += distance;
            comparisons++;
          }
        }

        final avgDistance = comparisons > 0 ? totalDistance / comparisons : double.infinity;

        // Índice de sustitución: más cercanos = más sustituibles
        final substitutionIndex = math.max(0.0, math.min(1.0, 1.0 - (avgDistance / 3.0)));

        // Elasticidad cruzada estimada
        // E_xy = β * índice_sustitución
        // β es positivo para bienes sustitutos
        final elasticity = substitutionIndex * 0.3; // Coeficiente positivo para sustitutos

        results.add(CrossElasticityResult(
          activity1: activity1,
          activity2: activity2,
          distance: avgDistance,
          substitutionIndex: substitutionIndex,
          elasticity: elasticity,
        ));
      }
    }

    // Ordenar por elasticidad descendente
    results.sort((a, b) => b.elasticity.compareTo(a.elasticity));

    return results;
  }

  /// Análisis de elasticidad ingreso (demanda)
  /// Relaciona población/disponibilidad económica con densidad de negocios
  static IncomeElasticityResult analyzeIncomeElasticity(
    String activity,
    List<Map<String, dynamic>> businesses,
    double population,
    double activePopulation, // PEA
    double radiusKm,
  ) {
    final area = calculateArea(radiusKm);
    final businessDensity = businesses.length / area; // negocios por km²

    // Población activa por km²
    final activePopulationDensity = activePopulation / area;

    // Elasticidad ingreso estimada
    // E_I = γ * (densidad_negocios / densidad_población_activa)
    // Mayor ratio = mayor elasticidad (más negocios por persona activa)
    final ratio = activePopulationDensity > 0 
        ? businessDensity / activePopulationDensity 
        : 0.0;

    // Normalizar y estimar elasticidad
    // Elasticidad ingreso típica: 0.5-2.0 para bienes normales
    final elasticity = math.min(2.0, math.max(0.0, ratio * 0.1));

    return IncomeElasticityResult(
      activity: activity,
      population: population,
      activePopulation: activePopulation,
      businessDensity: businessDensity,
      elasticity: elasticity,
      details: {
        'area_km2': area,
        'active_population_density': activePopulationDensity,
        'ratio_businesses_to_active_pop': ratio,
      },
    );
  }

  /// Análisis completo de elasticidad para todas las actividades
  static Map<String, IncomeElasticityResult> analyzeAllIncomeElasticities(
    List<Map<String, dynamic>> businesses,
    double population,
    double activePopulation,
    double radiusKm,
  ) {
    final results = <String, IncomeElasticityResult>{};

    // Agrupar por actividad
    final Map<String, List<Map<String, dynamic>>> byActivity = {};
    for (var business in businesses) {
      final activity = business['descripcion'] ?? business['codigo_actividad'] ?? 'Sin clasificar';
      if (!byActivity.containsKey(activity)) {
        byActivity[activity] = [];
      }
      byActivity[activity]!.add(business);
    }

    // Analizar cada actividad
    for (var entry in byActivity.entries) {
      final activity = entry.key;
      final activityBusinesses = entry.value;

      results[activity] = analyzeIncomeElasticity(
        activity,
        activityBusinesses,
        population,
        activePopulation,
        radiusKm,
      );
    }

    return results;
  }
}

