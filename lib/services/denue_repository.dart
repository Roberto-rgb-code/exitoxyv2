import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'denue_data.dart';

class MarketEntry {
  final String name;
  final String firm;
  final String activity;
  final String? postalCode;
  final LatLng position;
  final String? description;

  MarketEntry({
    required this.name,
    required this.firm,
    required this.activity,
    required this.position,
    this.postalCode,
    this.description,
  });
}

class DenueRepository {
  static String normalizeFirm(String raw) {
    var s = raw.toLowerCase().trim();
    s = s.replaceAll(RegExp(r'\s+'), ' ');
    s = s.replaceAll(RegExp(r'[.,\-_/]'), ' ');
    s = s.replaceAll(RegExp(
        r'\b(s\.?a\.?|s\.? de r\.?l\.?|s\.?c\.?|\bsa\b|\bsrl\b|sociedad|an[oó]nima|de|la|el|y)\b'), '');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s;
  }

  static Future<List<MarketEntry>> fetch({
    required String activity,
    required double lat,
    required double lon,
    String? postalCode,
    int radius = 1500,
  }) async {
    try {
      print('🔍 DenueRepository.fetch llamado para: "$activity" en ($lat, $lon)');
      final raw = await DenueApi.buscar(activity, '$lat', '$lon', radio: radius);
      print('📊 DenueApi.buscar devolvió: ${raw.length} elementos');
      
      final out = <MarketEntry>[];
      
      for (int i = 0; i < raw.length; i++) {
        final m = raw[i];
        if (i < 3) { // Debug primeros 3 elementos
          print('📋 Elemento $i: $m');
        }
        
        final name = (m['nombre'] ?? '').toString();
        if (name.isEmpty) {
          if (i < 3) print('⚠️ Elemento $i: nombre vacío, saltando');
          continue;
        }

        final firm = normalizeFirm(name);
        final description = (m['descripcion'] ?? '').toString();

        final latVal = double.tryParse('${m['lat']}');
        final lonVal = double.tryParse('${m['lon']}');
        if (latVal == null || lonVal == null) {
          if (i < 3) print('⚠️ Elemento $i: coordenadas inválidas (lat: ${m['lat']}, lon: ${m['lon']})');
          continue;
        }

        final entry = MarketEntry(
          name: name,
          firm: firm,
          activity: activity,
          postalCode: postalCode,
          position: LatLng(latVal, lonVal),
          description: description,
        );
        
        out.add(entry);
        if (i < 3) print('✅ Elemento $i agregado: $name en ($latVal, $lonVal)');
      }
      
      print('✅ DenueRepository.fetch devolvió: ${out.length} MarketEntry válidos');
      return out;
    } catch (e) {
      print('❌ Error fetching DENUE data: $e');
      return [];
    }
  }

  /// Alias para mantener compatibilidad con el código existente
  static Future<List<MarketEntry>> fetchEntries({
    required String activity,
    required double lat,
    required double lon,
    String? postalCode,
    int radius = 1500,
  }) async {
    return fetch(
      activity: activity,
      lat: lat,
      lon: lon,
      postalCode: postalCode,
      radius: radius,
    );
  }

  /// Valida si una actividad económica es válida en DENUE
  static Future<bool> isValidActivity(String activity) async {
    try {
      return await DenueApi.validaActividad(activity);
    } catch (e) {
      print('Error validating activity: $e');
      return false;
    }
  }
}
