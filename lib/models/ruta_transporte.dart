/// Modelo de datos para Rutas de Transporte
/// Capa: ZMG_Rutas-Mov
class RutaTransporte {
  final int id;
  final String? geomJson; // GeoJSON como string
  final String? name; // Nombre de la ruta
  final String? folderPath; // Carpeta/ubicación
  final double? shapeLeng; // Longitud de la ruta

  RutaTransporte({
    required this.id,
    this.geomJson,
    this.name,
    this.folderPath,
    this.shapeLeng,
  });

  factory RutaTransporte.fromJson(Map<String, dynamic> json) {
    return RutaTransporte(
      id: json['id'] as int,
      geomJson: json['geom_json'] as String?,
      name: json['NAME'] as String?,
      folderPath: json['FOLDERPATH'] as String?,
      shapeLeng: _toDouble(json['SHAPE_LENG']),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Información resumida para tooltips
  String get summaryInfo {
    return '${name ?? "Sin nombre"}\n'
        'Longitud: ${shapeLeng != null ? shapeLeng!.toStringAsFixed(2) : "N/A"} km';
  }
}

