import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'denue_data.dart';

class MarketEntry {
  final String name;
  final String firm;
  final String activity;
  final String? postalCode;
  final LatLng position;

  MarketEntry({
    required this.name,
    required this.firm,
    required this.activity,
    required this.position,
    this.postalCode,
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
  }) async {
    final raw = await DenueApi.buscar(activity, '$lat', '$lon');
    final out = <MarketEntry>[];
    for (final m in raw) {
      final name = (m['nombre'] ?? '').toString();
      if (name.isEmpty) continue;

      final firm = normalizeFirm(name);

      final latVal = double.tryParse('${m['lat']}');
      final lonVal = double.tryParse('${m['lon']}');
      if (latVal == null || lonVal == null) continue;

      out.add(MarketEntry(
        name: name,
        firm: firm,
        activity: activity,
        postalCode: postalCode,
        position: LatLng(latVal, lonVal),
      ));
    }
    return out;
  }
}
