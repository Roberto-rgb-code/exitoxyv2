// lib/services/ageb_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../core/config.dart';

class AgebApiService {
  /// Espera del back un JSON con esta estructura:
  /// {
  ///   "agebs": ["JAL001...", "JAL002..."],
  ///   "geometry": [ <lo que tu parser ya consume>, ... ],
  ///   "demografia": [ {"t":123, "m":60, "f":63}, ... ]
  /// }
  static Future<(List<String>, List<dynamic>, List<Map<String, dynamic>>)>
      getByCP(String cp) async {
    final url = Uri.parse('${Config.apiBaseUrl}/ageb/by-cp/$cp');
    final res = await http.get(url);

    if (res.statusCode != 200) {
      throw Exception('AGEB $cp: ${res.statusCode} ${res.body}');
    }

    final data = json.decode(res.body);
    final agebs = (data['agebs'] as List).cast<String>();
    final geometry = (data['geometry'] as List).toList();
    final demografia = (data['demografia'] as List)
        .map<Map<String, dynamic>>((e) => Map<String, dynamic>.from(e))
        .toList();

    return (agebs, geometry, demografia);
  }

  /// Si necesitas traer el polígono completo por idAgeb
  static Future<List<dynamic>> getPolygonByAgeb(String idAgeb) async {
    final url = Uri.parse('${Config.apiBaseUrl}/ageb/polygon/$idAgeb');
    final res = await http.get(url);
    if (res.statusCode != 200) {
      throw Exception('AGEB polygon $idAgeb: ${res.statusCode}');
    }
    final data = json.decode(res.body);
    // Estructura libre, devuélvelo tal cual (tu parser lo manejará)
    return (data['geometry'] as List).toList();
  }
}
