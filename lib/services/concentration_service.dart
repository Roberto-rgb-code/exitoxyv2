import 'package:kitit_v2/models/concentration_result.dart';
import 'package:kitit_v2/services/denue_repository.dart';

class ConcentrationService {
  /// Calcula el índice de concentración basado en las entradas DENUE
  static ConcentrationResult compute({
    required List<MarketEntry> entries,
    required String activity,
    required String postalCode,
  }) {
    if (entries.isEmpty) {
      return ConcentrationResult(
        hhi: 0,
        cr4: 0,
        level: 'low',
        color: 0xFF2e7d32,
        topChains: [],
      );
    }

    // Normalizar firmas y contar
    final counts = <String, int>{};
    for (final entry in entries) {
      final firm = entry.firm;
      if (firm.isNotEmpty) {
        counts.update(firm, (v) => v + 1, ifAbsent: () => 1);
      }
    }

    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return ConcentrationResult(
        hhi: 0,
        cr4: 0,
        level: 'low',
        color: 0xFF2e7d32,
        topChains: [],
      );
    }

    // Calcular cuotas de mercado
    final shares = <String, double>{};
    counts.forEach((k, v) => shares[k] = v / total);

    // HHI (0..10000 usando %^2)
    double hhi = 0;
    for (final share in shares.values) {
      final pct = share * 100.0;
      hhi += pct * pct;
    }

    // CR4 - concentración de las 4 empresas más grandes
    final top = shares.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top4 = top.take(4).toList();
    final cr4 = top4.fold<double>(0, (a, e) => a + (e.value * 100.0));

    // Clasificar nivel de concentración
    String level;
    int color;
    if (hhi < 1500) {
      level = 'low';
      color = 0xFF2e7d32; // verde
    } else if (hhi < 2500) {
      level = 'moderate';
      color = 0xFFf9a825; // ámbar
    } else if (hhi < 3500) {
      level = 'high';
      color = 0xFFef6c00; // naranja
    } else {
      level = 'veryHigh';
      color = 0xFFc62828; // rojo
    }

    final topChains = top.take(10).map((e) => e.key).toList();

    return ConcentrationResult(
      hhi: hhi,
      cr4: cr4,
      level: level,
      color: color,
      topChains: topChains,
    );
  }

  /// Obtiene el color para un nivel de concentración específico
  static int getColorForLevel(String level) {
    switch (level) {
      case 'low':
        return 0xFF2e7d32; // verde
      case 'moderate':
        return 0xFFf9a825; // ámbar
      case 'high':
        return 0xFFef6c00; // naranja
      case 'veryHigh':
        return 0xFFc62828; // rojo
      default:
        return 0xFF2e7d32; // verde por defecto
    }
  }

  /// Obtiene la etiqueta legible para un nivel
  static String getLevelLabel(String level) {
    switch (level) {
      case 'low':
        return 'Baja';
      case 'moderate':
        return 'Moderada';
      case 'high':
        return 'Alta';
      case 'veryHigh':
        return 'Muy alta';
      default:
        return 'Desconocida';
    }
  }
}