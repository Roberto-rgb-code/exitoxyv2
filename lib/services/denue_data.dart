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
    final url = Uri.parse(
      'https://www.inegi.org.mx/app/api/denue/v1/consulta/Buscar/$actividad/$lat,$lon/$radio/${Config.denueApiKey}',
    );
    final r = await http.get(url);
    if (r.statusCode != 200) {
      throw Exception('DENUE error ${r.statusCode}');
    }
    final data = json.decode(r.body);
    final out = <Map<String, dynamic>>[];
    for (final e in data) {
      out.add({
        'lat': e['Latitud'],
        'lon': e['Longitud'],
        'nombre': e['Nombre'],
        'descripcion': e['Clase_actividad'],
      });
    }
    return out;
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
