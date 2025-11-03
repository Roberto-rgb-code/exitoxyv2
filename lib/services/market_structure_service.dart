import 'dart:math' as math;

/// Modelo de resultado de análisis de estructura de mercado
class MarketStructureResult {
  final String actividad;
  final int nFirms;
  final double hhi;
  final double cr4;
  final String structure;
  final Map<String, int> firmUnits; // Empresa -> número de unidades
  final List<Map<String, dynamic>> firms; // Lista de empresas con detalles

  MarketStructureResult({
    required this.actividad,
    required this.nFirms,
    required this.hhi,
    required this.cr4,
    required this.structure,
    required this.firmUnits,
    required this.firms,
  });
}

/// Modelo de resultado de modelo económico
class EconomicModelResult {
  final String modelName;
  final Map<String, dynamic> parameters;
  final Map<String, double> results;

  EconomicModelResult({
    required this.modelName,
    required this.parameters,
    required this.results,
  });
}

class MarketStructureService {
  /// Calcula participaciones de mercado y CR4
  static Map<String, dynamic> calculateMarketShares(List<Map<String, dynamic>> businesses) {
    // Agrupar por nombre de empresa
    final Map<String, int> firmCounts = {};
    for (var business in businesses) {
      final firmName = business['nombre'] ?? 'Desconocido';
      firmCounts[firmName] = (firmCounts[firmName] ?? 0) + 1;
    }

    final totalUnits = firmCounts.values.reduce((a, b) => a + b);
    final marketShares = firmCounts.map((key, value) => 
      MapEntry(key, value / totalUnits)
    );

    // Calcular CR4 (concentración de las 4 mayores empresas)
    final sortedShares = marketShares.values.toList()..sort((a, b) => b.compareTo(a));
    final cr4 = sortedShares.take(4).reduce((a, b) => a + b);

    return {
      'firmUnits': firmCounts,
      'marketShares': marketShares,
      'cr4': cr4,
      'totalUnits': totalUnits,
    };
  }

  /// Calcula el índice Herfindahl-Hirschman (HHI)
  static double calculateHHI(Map<String, double> marketShares) {
    double hhi = 0.0;
    for (var share in marketShares.values) {
      hhi += share * share;
    }
    return hhi * 10000; // Escalar a 0-10000
  }

  /// Determina la estructura de mercado
  static String determineMarketStructure(double hhi, double cr4, int nFirms) {
    if (hhi > 7500 && cr4 > 0.9) {
      return 'Monopolio';
    } else if (hhi > 2500 && cr4 > 0.6) {
      return 'Oligopolio';
    } else if (hhi > 1500 && nFirms > 10) {
      return 'Competencia Monopolística';
    } else {
      return 'Competencia Perfecta';
    }
  }

  /// Analiza todas las actividades económicas
  static Map<String, List<String>> analyzeAllMarketStructures(List<Map<String, dynamic>> businesses) {
    final marketStructures = <String, List<String>>{
      'Monopolio': [],
      'Oligopolio': [],
      'Competencia Monopolística': [],
      'Competencia Perfecta': [],
    };

    // Agrupar por actividad económica
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

      final sharesData = calculateMarketShares(activityBusinesses);
      final hhi = calculateHHI(Map<String, double>.from(sharesData['marketShares'] as Map));
      final cr4 = sharesData['cr4'] as double;
      final nFirms = (sharesData['firmUnits'] as Map).length;

      final structure = determineMarketStructure(hhi, cr4, nFirms);
      marketStructures[structure]!.add(activity);
    }

    return marketStructures;
  }

  /// Analiza una actividad específica
  static MarketStructureResult analyzeActivity(
    String actividad,
    List<Map<String, dynamic>> businesses,
  ) {
    final activityBusinesses = businesses.where((b) => 
      (b['descripcion'] ?? b['codigo_actividad'] ?? '') == actividad
    ).toList();

    final sharesData = calculateMarketShares(activityBusinesses);
    final firmUnits = Map<String, int>.from(sharesData['firmUnits'] as Map);
    final marketShares = Map<String, double>.from(sharesData['marketShares'] as Map);
    final hhi = calculateHHI(marketShares);
    final cr4 = sharesData['cr4'] as double;
    final nFirms = firmUnits.length;

    final structure = determineMarketStructure(hhi, cr4, nFirms);

    // Crear lista de empresas con detalles
    final firms = firmUnits.entries.map((e) => {
      'nombre': e.key,
      'unidades': e.value,
      'participacion': marketShares[e.key] ?? 0.0,
    }).toList();

    return MarketStructureResult(
      actividad: actividad,
      nFirms: nFirms,
      hhi: hhi,
      cr4: cr4,
      structure: structure,
      firmUnits: firmUnits,
      firms: firms,
    );
  }

  // ========== MODELOS ECONÓMICOS ==========

  /// Modelo de Cournot para oligopolio
  static EconomicModelResult cournotModel(int nFirms, double a, double b, double c) {
    final q = nFirms * (a - c) / (b * (nFirms + 1));
    final p = a - b * q;
    final qIndividual = q / nFirms;
    final profitIndividual = (p - c) * qIndividual;

    return EconomicModelResult(
      modelName: 'Cournot',
      parameters: {'n': nFirms, 'a': a, 'b': b, 'c': c},
      results: {
        'Q_total': q,
        'P_equilibrio': p,
        'q_individual': qIndividual,
        'beneficio_individual': profitIndividual,
      },
    );
  }

  /// Modelo de Bertrand para oligopolio
  static EconomicModelResult bertrandModel(double c) {
    return EconomicModelResult(
      modelName: 'Bertrand',
      parameters: {'c': c},
      results: {
        'P_equilibrio': c,
        'beneficio_individual': 0.0,
      },
    );
  }

  /// Modelo de Stackelberg para oligopolio
  static EconomicModelResult stackelbergModel(double a, double b, double c) {
    final qLeader = (a - c) / (2 * b);
    final qFollower = (a - c - b * qLeader) / (2 * b);
    final qTotal = qLeader + qFollower;
    final p = a - b * qTotal;

    return EconomicModelResult(
      modelName: 'Stackelberg',
      parameters: {'a': a, 'b': b, 'c': c},
      results: {
        'q_lider': qLeader,
        'q_seguidor': qFollower,
        'Q_total': qTotal,
        'P_equilibrio': p,
        'beneficio_lider': (p - c) * qLeader,
        'beneficio_seguidor': (p - c) * qFollower,
      },
    );
  }

  /// Modelo de Cartel
  static EconomicModelResult cartelModel(int nFirms, double a, double b, double c) {
    final q = (a - c) / (2 * b);
    final p = a - b * q;
    final qIndividual = q / nFirms;
    final profitTotal = (p - c) * q;
    final profitIndividual = profitTotal / nFirms;

    return EconomicModelResult(
      modelName: 'Cartel',
      parameters: {'n': nFirms, 'a': a, 'b': b, 'c': c},
      results: {
        'Q_total': q,
        'P_equilibrio': p,
        'q_individual': qIndividual,
        'beneficio_total': profitTotal,
        'beneficio_individual': profitIndividual,
      },
    );
  }

  /// Modelo de competencia perfecta
  static EconomicModelResult perfectCompetitionModel(double a, double b, double c) {
    final p = c;
    final q = (a - p) / b;

    return EconomicModelResult(
      modelName: 'Competencia Perfecta',
      parameters: {'a': a, 'b': b, 'c': c},
      results: {
        'P_equilibrio': p,
        'Q_total': q,
      },
    );
  }

  /// Modelo de competencia monopolística
  static EconomicModelResult monopolisticCompetitionModel(
    int nFirms,
    double a,
    double b,
    double c,
    double d,
  ) {
    final p = (a + c) / 2;
    final q = (a - p) / (b * (1 + d));
    final qTotal = nFirms * q;

    return EconomicModelResult(
      modelName: 'Competencia Monopolística',
      parameters: {'n': nFirms, 'a': a, 'b': b, 'c': c, 'd': d},
      results: {
        'P_equilibrio': p,
        'q_individual': q,
        'Q_total': qTotal,
      },
    );
  }

  /// Modelo de monopolio
  static EconomicModelResult monopolyModel(double a, double b, double c) {
    final q = (a - c) / (2 * b);
    final p = a - b * q;
    final profit = (p - c) * q;

    return EconomicModelResult(
      modelName: 'Monopolio',
      parameters: {'a': a, 'b': b, 'c': c},
      results: {
        'Q_total': q,
        'P_equilibrio': p,
        'beneficio': profit,
      },
    );
  }
}

