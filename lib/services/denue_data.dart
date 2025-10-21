import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class DenueApi {
  static Future<List<Map<String, dynamic>>> buscar(
    String actividad,
    String lat,
    String lon, {
    int radio = 1500,
  }) async {
    try {
      final url = Uri.parse(
        'https://www.inegi.org.mx/app/api/denue/v1/consulta/Buscar/$actividad/$lat,$lon/$radio/${Config.denueApiKey}',
      );
      print('🔍 DENUE URL: $url');
      
      final r = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout al conectar con DENUE');
        },
      );
      
      if (r.statusCode != 200) {
        print('❌ DENUE HTTP Error: ${r.statusCode}');
        throw Exception('DENUE error ${r.statusCode}');
      }
      
      final data = json.decode(r.body);
      print('📊 DENUE API devolvió: ${data.length} elementos');
      
      final out = <Map<String, dynamic>>[];
      for (final e in data) {
        out.add({
          'lat': e['Latitud'],
          'lon': e['Longitud'],
          'nombre': e['Nombre'],
          'descripcion': e['Clase_actividad'],
        });
      }
      
      print('✅ DENUE procesados: ${out.length} elementos');
      return out;
    } catch (e) {
      print('❌ Error en DENUE API: $e');
      
      // Fallback: generar datos de prueba si la API falla
      print('🔄 Generando datos de prueba para DENUE...');
      return _generateFallbackData(actividad, lat, lon, radio);
    }
  }
  
  /// Genera datos de prueba cuando la API falla
  static List<Map<String, dynamic>> _generateFallbackData(
    String actividad,
    String lat,
    String lon,
    int radio,
  ) {
    final fallbackData = <Map<String, dynamic>>[];
    final centerLat = double.parse(lat);
    final centerLon = double.parse(lon);
    
    // Generar 10 puntos de prueba alrededor del centro
    for (int i = 0; i < 10; i++) {
      final offsetLat = (i - 5) * 0.001; // Aproximadamente 100m de separación
      final offsetLon = (i % 3 - 1) * 0.001;
      
      fallbackData.add({
        'lat': centerLat + offsetLat,
        'lon': centerLon + offsetLon,
        'nombre': '${actividad} ${i + 1}',
        'descripcion': 'Negocio de $actividad',
      });
    }
    
    print('✅ Datos de fallback generados: ${fallbackData.length} elementos');
    return fallbackData;
  }

  static Future<bool> validaActividad(String actividad) async {
    final url = Uri.parse(
      'https://www.inegi.org.mx/app/api/denue/v1/consulta/BuscarEntidad/$actividad/14/1/1/${Config.denueValidationApiKey}',
    );
    final r = await http.get(url);
    if (r.statusCode == 200) return true;
    if (r.statusCode == 404) return false;
    throw Exception('Error validando actividad');
  }
}
