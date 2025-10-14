import 'package:kitit_v2/models/concentration_result.dart';

class Recommendation {
  final String title;
  final String description;
  final String type; // 'success', 'warning', 'info', 'error'
  final List<String> details;
  final double score; // 0-100

  const Recommendation({
    required this.title,
    required this.description,
    required this.type,
    required this.details,
    required this.score,
  });
}

class RecommendationService {
  /// Genera recomendaciones basadas en el análisis de concentración y demografía
  static List<Recommendation> generateRecommendations({
    required ConcentrationResult concentration,
    required Map<String, int> demography,
    required String activity,
    required String postalCode,
  }) {
    final recommendations = <Recommendation>[];

    // Análisis de concentración
    recommendations.addAll(_analyzeConcentration(concentration, activity));
    
    // Análisis demográfico
    recommendations.addAll(_analyzeDemography(demography, activity));
    
    // Análisis de oportunidad de mercado
    recommendations.addAll(_analyzeMarketOpportunity(concentration, demography, activity));

    // Ordenar por score (mayor a menor)
    recommendations.sort((a, b) => b.score.compareTo(a.score));
    
    return recommendations;
  }

  static List<Recommendation> _analyzeConcentration(ConcentrationResult concentration, String activity) {
    final recommendations = <Recommendation>[];

    switch (concentration.level) {
      case 'low':
        recommendations.add(Recommendation(
          title: 'Excelente Oportunidad de Mercado',
          description: 'La baja concentración indica un mercado fragmentado con oportunidades para nuevos competidores.',
          type: 'success',
          score: 85.0,
          details: [
            'HHI de ${concentration.hhi.toStringAsFixed(0)} indica competencia saludable',
            'CR4 de ${concentration.cr4.toStringAsFixed(1)}% muestra que ninguna empresa domina',
            'Oportunidad para diferenciación y captura de mercado',
          ],
        ));
        break;

      case 'moderate':
        recommendations.add(Recommendation(
          title: 'Mercado Moderadamente Competitivo',
          description: 'La concentración moderada sugiere un mercado estable con algunas oportunidades.',
          type: 'info',
          score: 65.0,
          details: [
            'HHI de ${concentration.hhi.toStringAsFixed(0)} indica competencia moderada',
            'CR4 de ${concentration.cr4.toStringAsFixed(1)}% muestra cierta concentración',
            'Estrategia de nicho podría ser efectiva',
          ],
        ));
        break;

      case 'high':
        recommendations.add(Recommendation(
          title: 'Mercado Altamente Concentrado',
          description: 'La alta concentración indica un mercado dominado por pocas empresas.',
          type: 'warning',
          score: 35.0,
          details: [
            'HHI de ${concentration.hhi.toStringAsFixed(0)} indica alta concentración',
            'CR4 de ${concentration.cr4.toStringAsFixed(1)}% muestra dominio de pocas empresas',
            'Se requiere estrategia diferenciada y capital significativo',
          ],
        ));
        break;

      case 'veryHigh':
        recommendations.add(Recommendation(
          title: 'Mercado Oligopólico',
          description: 'La muy alta concentración indica un mercado dominado por oligopolio.',
          type: 'error',
          score: 15.0,
          details: [
            'HHI de ${concentration.hhi.toStringAsFixed(0)} indica oligopolio',
            'CR4 de ${concentration.cr4.toStringAsFixed(1)}% muestra dominio total',
            'Muy difícil entrar al mercado sin ventaja competitiva significativa',
          ],
        ));
        break;
    }

    return recommendations;
  }

  static List<Recommendation> _analyzeDemography(Map<String, int> demography, String activity) {
    final recommendations = <Recommendation>[];
    final total = demography['t'] ?? 0;
    final hombres = demography['m'] ?? 0;
    final mujeres = demography['f'] ?? 0;

    if (total == 0) return recommendations;

    // Análisis de tamaño de población
    if (total > 10000) {
      recommendations.add(Recommendation(
        title: 'Alta Densidad Poblacional',
        description: 'La zona tiene una población significativa que puede soportar múltiples negocios.',
        type: 'success',
        score: 75.0,
        details: [
          'Población total: $total habitantes',
          'Mercado potencial amplio',
          'Oportunidad para especialización',
        ],
      ));
    } else if (total > 5000) {
      recommendations.add(Recommendation(
        title: 'Población Moderada',
        description: 'La zona tiene una población moderada adecuada para ciertos tipos de negocios.',
        type: 'info',
        score: 55.0,
        details: [
          'Población total: $total habitantes',
          'Mercado de tamaño medio',
          'Considerar nichos específicos',
        ],
      ));
    } else {
      recommendations.add(Recommendation(
        title: 'Población Baja',
        description: 'La zona tiene una población limitada que puede restringir el potencial de mercado.',
        type: 'warning',
        score: 30.0,
        details: [
          'Población total: $total habitantes',
          'Mercado limitado',
          'Requiere análisis cuidadoso de demanda',
        ],
      ));
    }

    // Análisis de distribución por género
    final ratioHombres = (hombres / total) * 100;
    final ratioMujeres = (mujeres / total) * 100;

    if (_isGenderRelevantActivity(activity)) {
      if (ratioMujeres > 60) {
        recommendations.add(Recommendation(
          title: 'Población Mayoritariamente Femenina',
          description: 'La zona tiene una proporción alta de mujeres, relevante para ciertos negocios.',
          type: 'info',
          score: 60.0,
          details: [
            '${ratioMujeres.toStringAsFixed(1)}% mujeres vs ${ratioHombres.toStringAsFixed(1)}% hombres',
            'Considerar productos/servicios orientados a mujeres',
          ],
        ));
      } else if (ratioHombres > 60) {
        recommendations.add(Recommendation(
          title: 'Población Mayoritariamente Masculina',
          description: 'La zona tiene una proporción alta de hombres, relevante para ciertos negocios.',
          type: 'info',
          score: 60.0,
          details: [
            '${ratioHombres.toStringAsFixed(1)}% hombres vs ${ratioMujeres.toStringAsFixed(1)}% mujeres',
            'Considerar productos/servicios orientados a hombres',
          ],
        ));
      }
    }

    return recommendations;
  }

  static List<Recommendation> _analyzeMarketOpportunity(
    ConcentrationResult concentration,
    Map<String, int> demography,
    String activity,
  ) {
    final recommendations = <Recommendation>[];
    final total = demography['t'] ?? 0;

    // Score combinado
    double marketScore = 0;
    
    // Factor de concentración (inverso - menor concentración = mayor oportunidad)
    switch (concentration.level) {
      case 'low':
        marketScore += 40;
        break;
      case 'moderate':
        marketScore += 25;
        break;
      case 'high':
        marketScore += 10;
        break;
      case 'veryHigh':
        marketScore += 0;
        break;
    }

    // Factor de población
    if (total > 10000) {
      marketScore += 30;
    } else if (total > 5000) {
      marketScore += 20;
    } else if (total > 2000) {
      marketScore += 10;
    }

    // Factor de actividad específica
    marketScore += _getActivityScore(activity);

    if (marketScore > 70) {
      recommendations.add(Recommendation(
        title: 'Excelente Oportunidad de Negocio',
        description: 'La combinación de factores indica una excelente oportunidad para este tipo de negocio.',
        type: 'success',
        score: marketScore,
        details: [
          'Score de oportunidad: ${marketScore.toStringAsFixed(0)}/100',
          'Baja competencia y buena población objetivo',
          'Recomendado proceder con el análisis detallado',
        ],
      ));
    } else if (marketScore > 50) {
      recommendations.add(Recommendation(
        title: 'Oportunidad Moderada',
        description: 'La zona presenta una oportunidad moderada que requiere análisis adicional.',
        type: 'info',
        score: marketScore,
        details: [
          'Score de oportunidad: ${marketScore.toStringAsFixed(0)}/100',
          'Considerar factores adicionales como ubicación y accesibilidad',
          'Análisis de competencia directa recomendado',
        ],
      ));
    } else {
      recommendations.add(Recommendation(
        title: 'Oportunidad Limitada',
        description: 'La zona presenta desafíos significativos para este tipo de negocio.',
        type: 'warning',
        score: marketScore,
        details: [
          'Score de oportunidad: ${marketScore.toStringAsFixed(0)}/100',
          'Alta competencia o población insuficiente',
          'Considerar otras ubicaciones o modelos de negocio',
        ],
      ));
    }

    return recommendations;
  }

  static bool _isGenderRelevantActivity(String activity) {
    final genderRelevantActivities = [
      'belleza', 'salon', 'spa', 'moda', 'ropa', 'zapatos',
      'herramientas', 'automotriz', 'deportes', 'fitness'
    ];
    
    final activityLower = activity.toLowerCase();
    return genderRelevantActivities.any((relevant) => activityLower.contains(relevant));
  }

  static double _getActivityScore(String activity) {
    final activityLower = activity.toLowerCase();
    
    // Actividades de alta demanda
    if (activityLower.contains('abarrotes') || 
        activityLower.contains('supermercado') ||
        activityLower.contains('farmacia')) {
      return 20;
    }
    
    // Actividades de demanda media
    if (activityLower.contains('restaurante') ||
        activityLower.contains('cafeteria') ||
        activityLower.contains('tienda')) {
      return 15;
    }
    
    // Actividades especializadas
    if (activityLower.contains('belleza') ||
        activityLower.contains('salon') ||
        activityLower.contains('spa')) {
      return 10;
    }
    
    return 5; // Score base
  }
}
