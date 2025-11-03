import 'dart:convert';

/// Modelo de datos para Estaciones de Transporte
/// Capa: estaciones_de_transporte_masivo
class EstacionTransporte {
  final int id;
  final String? geomJson; // GeoJSON como string
  final String? nombre; // Nombre de la estación
  final String? sistema; // BRT, Tren Ligero, etc.
  final String? estructura; // Superficie, Elevada, Subterránea
  final String? estado; // Existente, Propuesto
  final String? linea; // Línea del sistema

  EstacionTransporte({
    required this.id,
    this.geomJson,
    this.nombre,
    this.sistema,
    this.estructura,
    this.estado,
    this.linea,
  });

  factory EstacionTransporte.fromJson(Map<String, dynamic> json) {
    return EstacionTransporte(
      id: json['id'] as int,
      geomJson: json['geom_json'] as String?,
      nombre: json['Nombre_de_'] as String?,
      sistema: json['Sistema'] as String?,
      estructura: json['Estructura'] as String?,
      estado: json['Estado'] as String?,
      linea: json['Lnea_y_si'] as String?,
    );
  }

  /// Obtener coordenadas (para marcador en mapa)
  Map<String, double>? get coordinates {
    if (geomJson == null) return null;
    try {
      final geom = json.decode(geomJson!);
      if (geom['type'] == 'MultiPoint') {
        final coords = geom['coordinates'] as List;
        if (coords.isNotEmpty && coords[0].isNotEmpty) {
          return {
            'longitude': coords[0][0] as double,
            'latitude': coords[0][1] as double,
          };
        }
      }
    } catch (e) {
      print('Error obteniendo coordenadas: $e');
    }
    return null;
  }

  /// Información resumida para tooltips
  String get summaryInfo {
    return '${nombre ?? "Sin nombre"}\n'
        'Sistema: ${sistema ?? "N/A"}\n'
        'Estado: ${estado ?? "N/A"}';
  }
}

