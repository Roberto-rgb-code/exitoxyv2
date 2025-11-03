import 'dart:convert';

/// Modelo de datos para Colonias (ISDCOL2020_2021F)
/// Capa: ISDCOL2020_2021F - Censo de colonias con datos demográficos
class CensoAgeb {
  final int id;
  final String? geomJson; // GeoJSON como string
  final int? numcol;
  final String? muns; // Municipio
  final String? nombre; // Nombre de la colonia
  final int? cp; // Código postal
  final double? supm2; // Superficie en m²
  
  // Demografía básica
  final int? pobtot; // Población total
  final int? pobfem; // Población femenina
  final int? pobmas; // Población masculina
  
  // Educación
  final double? graproes; // Grado promedio de escolaridad
  final double? graproesF;
  final double? graproesM;
  
  // Ocupación
  final int? pea; // Población económicamente activa
  final int? peaF;
  final int? peaM;
  final int? peInac; // Población económicamente inactiva
  final int? pocupada; // Población ocupada
  final int? pdesocup; // Población desocupada
  
  // Vivienda
  final int? vvtot; // Total de viviendas
  final int? tvivhab; // Viviendas habitadas
  final double? promOcup; // Promedio de ocupantes
  
  // Discapacidades
  final int? pconDisc; // Población con discapacidad
  final int? pconLim; // Población con limitación
  final int? psindLim; // Población sin limitación

  CensoAgeb({
    required this.id,
    this.geomJson,
    this.numcol,
    this.muns,
    this.nombre,
    this.cp,
    this.supm2,
    this.pobtot,
    this.pobfem,
    this.pobmas,
    this.graproes,
    this.graproesF,
    this.graproesM,
    this.pea,
    this.peaF,
    this.peaM,
    this.peInac,
    this.pocupada,
    this.pdesocup,
    this.vvtot,
    this.tvivhab,
    this.promOcup,
    this.pconDisc,
    this.pconLim,
    this.psindLim,
  });

  factory CensoAgeb.fromJson(Map<String, dynamic> json) {
    return CensoAgeb(
      id: json['id'] as int,
      geomJson: json['geom_json'] as String?,
      numcol: _toInt(json['NUMCOL']),
      muns: json['MUNS'] as String?,
      nombre: json['NOMBRE'] as String?,
      cp: _toInt(json['CP']),
      supm2: _toDouble(json['supm2']),
      pobtot: _toInt(json['POBTOT']),
      pobfem: _toInt(json['POBFEM']),
      pobmas: _toInt(json['POBMAS']),
      graproes: _toDouble(json['GRAPROES']),
      graproesF: _toDouble(json['GRAPROES_F']),
      graproesM: _toDouble(json['GRAPROES_M']),
      pea: _toInt(json['PEA']),
      peaF: _toInt(json['PEA_F']),
      peaM: _toInt(json['PEA_M']),
      peInac: _toInt(json['PE_INAC']),
      pocupada: _toInt(json['POCUPADA']),
      pdesocup: _toInt(json['PDESOCUP']),
      vvtot: _toInt(json['VIVTOT']),
      tvivhab: _toInt(json['TVIVHAB']),
      promOcup: _toDouble(json['PROM_OCUP']),
      pconDisc: _toInt(json['PCON_DISC']),
      pconLim: _toInt(json['PCON_LIM']),
      psindLim: _toInt(json['PSIND_LIM']),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Obtener coordenadas del centroide (para marcador en mapa)
  Map<String, double>? get centroid {
    if (geomJson == null) return null;
    try {
      final geom = json.decode(geomJson!);
      if (geom['type'] == 'MultiPolygon') {
        // Calcular centroide aproximado (promedio de coordenadas)
        final coords = geom['coordinates'] as List;
        double latSum = 0;
        double lonSum = 0;
        int count = 0;
        
        for (var polygon in coords) {
          for (var ring in polygon as List) {
            for (var coord in ring as List) {
              lonSum += coord[0] as double;
              latSum += coord[1] as double;
              count++;
            }
          }
        }
        
        if (count > 0) {
          return {
            'longitude': lonSum / count,
            'latitude': latSum / count,
          };
        }
      }
    } catch (e) {
      print('Error calculando centroide: $e');
    }
    return null;
  }

  /// Información resumida para tooltips
  String get summaryInfo {
    return '${nombre ?? "Sin nombre"}\n'
        'Población: ${pobtot ?? "N/A"}\n'
        'Superficie: ${supm2 != null ? (supm2! / 10000).toStringAsFixed(2) : "N/A"} ha';
  }
}

