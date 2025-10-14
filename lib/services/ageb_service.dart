import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

/// Para Android emulator usa 10.0.2.2 en lugar de localhost.
const String _base = String.fromEnvironment(
  'AGEB_BASE_URL',
  defaultValue: 'http://10.0.2.2:3001',
);

class AgebPolygon {
  final String id;
  final List<LatLng> points;
  AgebPolygon({required this.id, required this.points});
}

class AgebService {
  static Future<List<AgebPolygon>> byCp(String cp) async {
    final url = Uri.parse('$_base/ageb/by-cp/$cp');
    final r = await http.get(url);
    if (r.statusCode != 200) {
      throw Exception('AGEB by CP $cp -> ${r.statusCode}');
    }
    final List data = json.decode(r.body);
    return data.map<AgebPolygon>((e) {
      final coords = (e['coords'] as List)
          .map<LatLng>((p) => LatLng(p[1] * 1.0, p[0] * 1.0))
          .toList();
      return AgebPolygon(id: e['id'].toString(), points: coords);
    }).toList();
  }

  static Future<Map<String, dynamic>> demoAggByCp(String cp) async {
    final url = Uri.parse('$_base/ageb/demo/$cp');
    final r = await http.get(url);
    if (r.statusCode != 200) throw Exception('AGEB demo $cp');
    return json.decode(r.body) as Map<String, dynamic>;
  }
}
