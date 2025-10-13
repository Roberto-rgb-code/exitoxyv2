// lib/models/concentration_result.dart
class ConcentrationResult {
  final double hhi;        // Índice Herfindahl-Hirschman (0–10,000 aprox si %^2)
  final double cr4;        // Suma de cuotas de las 4 cadenas más grandes (0–100)
  final String level;      // low | moderate | high | veryHigh
  final int color;         // ARGB (0xFF....)
  final List<String> topChains;

  const ConcentrationResult({
    required this.hhi,
    required this.cr4,
    required this.level,
    required this.color,
    required this.topChains,
  });

  ConcentrationResult copyWith({
    double? hhi,
    double? cr4,
    String? level,
    int? color,
    List<String>? topChains,
  }) {
    return ConcentrationResult(
      hhi: hhi ?? this.hhi,
      cr4: cr4 ?? this.cr4,
      level: level ?? this.level,
      color: color ?? this.color,
      topChains: topChains ?? this.topChains,
    );
  }
}
