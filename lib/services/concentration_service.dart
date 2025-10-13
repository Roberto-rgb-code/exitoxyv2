import 'dart:math';
import '../models/concentration_result.dart';

// Paleta simple
class _C {
  static const low = 0xFFBFE8C2;       // verde claro
  static const moderate = 0xFFFFE59D;  // amarillo
  static const high = 0xFFFFC37D;      // naranja
  static const veryHigh = 0xFFFF8A80;  // rojo
}

enum ConcentrationLevel { low, moderate, high, veryHigh }

class ConcentrationService {
  /// Calcula HHI y CR4 desde un mapa {cadena: conteo}
  ConcentrationResult calculate(Map<String, int> counts) {
    if (counts.isEmpty) {
      return const ConcentrationResult(
        hhi: 0,
        cr4: 0,
        level: 'low',
        color: _C.low,
        topChains: [],
      );
    }

    final total = counts.values.fold<int>(0, (a, b) => a + b);
    if (total == 0) {
      return const ConcentrationResult(
        hhi: 0,
        cr4: 0,
        level: 'low',
        color: _C.low,
        topChains: [],
      );
    }

    // HHI: suma de (cuota en %)^2
    double hhi = 0;
    for (final v in counts.values) {
      final s = (v / total) * 100.0;
      hhi += s * s;
    }

    // CR4: suma de las 4 cuotas más grandes
    final sorted = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top4 = sorted.take(min(4, sorted.length)).toList();
    final cr4 = top4.fold<double>(0, (a, e) => a + (e.value / total) * 100.0);

    final lvl = _bucket(hhi);
    final color = _levelColor(lvl);

    return ConcentrationResult(
      hhi: hhi,
      cr4: cr4,
      level: lvl.name,
      color: color,
      topChains: top4.map((e) => e.key).toList(growable: false),
    );
  }

  ConcentrationLevel _bucket(double hhi) {
    if (hhi < 1500) return ConcentrationLevel.low;
    if (hhi < 2500) return ConcentrationLevel.moderate;
    if (hhi < 3500) return ConcentrationLevel.high;
    return ConcentrationLevel.veryHigh;
  }

  int _levelColor(ConcentrationLevel l) {
    switch (l) {
      case ConcentrationLevel.low:
        return _C.low;
      case ConcentrationLevel.moderate:
        return _C.moderate;
      case ConcentrationLevel.high:
        return _C.high;
      case ConcentrationLevel.veryHigh:
        return _C.veryHigh;
    }
  }
}
