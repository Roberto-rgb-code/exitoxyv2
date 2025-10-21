class DelitoModel {
  final String fecha;
  final String delito;
  final double x; // Longitud
  final double y; // Latitud
  final String colonia;
  final String municipio;
  final String claveMun;
  final String hora;
  final String bienAfectado;
  final String zonaGeografica;

  DelitoModel({
    required this.fecha,
    required this.delito,
    required this.x,
    required this.y,
    required this.colonia,
    required this.municipio,
    required this.claveMun,
    required this.hora,
    required this.bienAfectado,
    required this.zonaGeografica,
  });

  factory DelitoModel.fromCsvRow(List<dynamic> row) {
    // Limpiar comillas de los strings
    String cleanString(dynamic value) {
      if (value == null) return '';
      String str = value.toString();
      if (str.startsWith('"') && str.endsWith('"')) {
        str = str.substring(1, str.length - 1);
      }
      return str;
    }
    
    // Función para parsear números
    double parseDouble(dynamic value) {
      if (value == null) return 0.0;
      String str = cleanString(value);
      return double.tryParse(str) ?? 0.0;
    }
    
    return DelitoModel(
      fecha: cleanString(row[0]),
      delito: cleanString(row[1]),
      x: parseDouble(row[2]),
      y: parseDouble(row[3]),
      colonia: cleanString(row[4]),
      municipio: cleanString(row[5]),
      claveMun: cleanString(row[6]),
      hora: cleanString(row[7]),
      bienAfectado: cleanString(row[8]),
      zonaGeografica: cleanString(row[9]),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fecha': fecha,
      'delito': delito,
      'x': x,
      'y': y,
      'colonia': colonia,
      'municipio': municipio,
      'claveMun': claveMun,
      'hora': hora,
      'bienAfectado': bienAfectado,
      'zonaGeografica': zonaGeografica,
    };
  }

  factory DelitoModel.fromMap(Map<String, dynamic> map) {
    return DelitoModel(
      fecha: map['fecha'] ?? '',
      delito: map['delito'] ?? '',
      x: map['x']?.toDouble() ?? 0.0,
      y: map['y']?.toDouble() ?? 0.0,
      colonia: map['colonia'] ?? '',
      municipio: map['municipio'] ?? '',
      claveMun: map['claveMun'] ?? '',
      hora: map['hora'] ?? '',
      bienAfectado: map['bienAfectado'] ?? '',
      zonaGeografica: map['zonaGeografica'] ?? '',
    );
  }

  @override
  String toString() {
    return 'DelitoModel(fecha: $fecha, delito: $delito, colonia: $colonia, municipio: $municipio)';
  }
}
