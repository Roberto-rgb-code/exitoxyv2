import 'dart:convert';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

// Usa tu helper actual. No lo borres.
import 'excel_reader.dart';
import '../core/config.dart';

class PredioInfo {
  final String cuentaCatastral;
  final String usoDeSuelo;   // texto legible
  final double superficie;   // m² si viene del API; si no, 0
  final String domicilio;

  PredioInfo({
    required this.cuentaCatastral,
    required this.usoDeSuelo,
    required this.superficie,
    required this.domicilio,
  });
}

/// Mapeo corto de claves → nombre legible (subset útil)
const Map<String, String> _tiposUsoNombre = {
  'H': 'Habitacional',
  'H1': 'Habitacional 1',
  'H2': 'Habitacional 2',
  'H3': 'Habitacional 3',
  'H4': 'Habitacional 4',
  'H5': 'Habitacional 5',
  'CS': 'Comercio y Servicios',
  'CS1': 'Comercio y Servicios (Impacto mínimo)',
  'CS2': 'Comercio y Servicios (Impacto bajo)',
  'CS3': 'Comercio y Servicios (Impacto medio)',
  'CS4': 'Comercio y Servicios (Impacto alto)',
  'CS5': 'Comercio y Servicios (Impacto máximo)',
  'I': 'Industrial',
  'E': 'Equipamiento',
  'EA': 'Espacio Abierto',
  'ANP': 'Área Natural Protegida',
  'PC': 'Conservación',
  'AP': 'Administración Pública',
};

String _usoLegible(dynamic clave) {
  final k = (clave ?? '').toString().toUpperCase();
  return _tiposUsoNombre[k] ?? (k.isEmpty ? 'Desconocido' : k);
}

class PredioService {
  static String get _base => Config.visorUrbanoApiUrl;

  /// Busca un predio por dirección (calle + número exterior).
  Future<PredioInfo?> fetchPredioByDireccion({
    required String calle,
    required String numeroExterior,
  }) async {
    final uri = Uri.parse('$_base/predio/search?calle=$calle&numeroExterior=$numeroExterior');

    final res = await http.get(uri);
    if (res.statusCode != 200) throw Exception('VisorUrbano/search ${res.statusCode}');

    final data = json.decode(res.body);

    // El API regresa una lista; tomamos el primer match si existe.
    if (data is List && data.isNotEmpty) {
      final m = data.first as Map<String, dynamic>;
      return _fromApiMap(m);
    }
    return null;
  }

  /// Busca un predio por coordenadas (lat/lng WGS84).
  /// El endpoint del API espera coordenadas UTM → usamos tu ExcelReader.
  Future<PredioInfo?> fetchPredioByLatLng(LatLng p) async {
    print('🔍 Buscando predio en coordenadas: ${p.latitude}, ${p.longitude}');
    
    List<double> utm;
    try {
      utm = await ExcelReader.modifyLatAndLon(p.latitude, p.longitude);
      print('📍 Coordenadas UTM: ${utm[0]}, ${utm[1]}');
      // Se espera [este, norte]; si tu helper regresa otro orden, ajústalo aquí.
      if (utm.length < 2) throw Exception('Conversión UTM inválida');
    } catch (e) {
      print('❌ Error en conversión UTM: $e');
      // Si falla la conversión, devolvemos null en lugar de datos dummy
      return null;
    }

    final url = '$_base/predio/${utm[0]}/${utm[1]}';
    print('🌐 Consultando API: $url');
    
    try {
      final res = await http.get(Uri.parse(url));
      print('📡 Respuesta API: ${res.statusCode}');
      
      if (res.statusCode != 200) {
        print('❌ Error API: ${res.statusCode} - ${res.body}');
        return null;
      }

      final data = json.decode(res.body);
      print('📊 Datos recibidos: $data');

      if (data is Map<String, dynamic>) {
        return _fromApiMap(data);
      }
      return null;
    } catch (e) {
      print('❌ Error en petición HTTP: $e');
      return null;
    }
  }

  // ----------------- Helpers -----------------

  PredioInfo _fromApiMap(Map<String, dynamic> m) {
    // Campos típicos; ajusta llaves si tu API real usa otros nombres.
    final cuenta = (m['cuentaCatastral'] ?? m['cuenta'] ?? '').toString();
    final usoClave = m['uso'] ?? m['uso_suelo'] ?? m['claveUso'];
    final uso = _usoLegible(usoClave);

    // Superficie puede venir como número o string → normalizamos
    final supRaw = m['superficie'] ?? m['area'] ?? m['superficie_m2'];
    final sup = switch (supRaw) {
      num n => n.toDouble(),
      String s => double.tryParse(s) ?? 0.0,
      _ => 0.0,
    };

    // Armamos un domicilio legible con lo que exista
    final calle = (m['calle'] ?? m['domicilio'] ?? m['direccion'] ?? '').toString();
    final numero = (m['numeroExterior'] ?? m['numero'] ?? '').toString();
    final colonia = (m['colonia'] ?? '').toString();
    final muni = (m['municipio'] ?? 'Guadalajara').toString();
    final edo = (m['estado'] ?? 'Jal.').toString();

    final domicilio = [
      if (calle.isNotEmpty) calle,
      if (numero.isNotEmpty) '#$numero',
      if (colonia.isNotEmpty) colonia,
      muni,
      edo,
    ].where((s) => s.trim().isNotEmpty).join(', ');

    return PredioInfo(
      cuentaCatastral: cuenta.isEmpty ? 'SIN-CUENTA' : cuenta,
      usoDeSuelo: uso,
      superficie: sup,
      domicilio: domicilio,
    );
  }
}
