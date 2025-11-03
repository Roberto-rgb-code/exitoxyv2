/// Modelo de datos para Líneas de Transporte Masivo y Alimentadores
/// Capa: vwtransporte_masivo_y_alimentador_2022
class LineaTransporte {
  final int id;
  final String? geomJson; // GeoJSON como string
  final String? tipoCo; // Tipo de corredor (Masivo, Alimentador)
  final String? tipo; // Tipo de línea
  final String? nombre; // Nombre de la línea
  final String? estado; // Existente, Propuesto

  LineaTransporte({
    required this.id,
    this.geomJson,
    this.tipoCo,
    this.tipo,
    this.nombre,
    this.estado,
  });

  factory LineaTransporte.fromJson(Map<String, dynamic> json) {
    return LineaTransporte(
      id: json['id'] as int,
      geomJson: json['geom_json'] as String?,
      tipoCo: json['Tipo_de_co'] as String?,
      tipo: json['Tipo'] as String?,
      nombre: json['Nombre'] as String?,
      estado: json['Estado'] as String?,
    );
  }

  /// Información resumida para tooltips
  String get summaryInfo {
    return '${nombre ?? "Sin nombre"}\n'
        'Tipo: ${tipoCo ?? "N/A"}\n'
        'Estado: ${estado ?? "N/A"}';
  }
}

