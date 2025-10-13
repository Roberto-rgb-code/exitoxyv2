import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolygonsParser {
  /// Convierte geometrías (WKT/GeoJSON/List) a una lista de LatLng.
  static List<LatLng> geometryToLatLng(dynamic geometry) {
    // WKT: POLYGON((lon lat, lon lat, ...))
    if (geometry is String) {
      final s = geometry.trim();
      final upper = s.toUpperCase();

      if (upper.startsWith('POLYGON')) {
        final start = s.indexOf('((');
        final end = s.lastIndexOf('))');
        if (start != -1 && end != -1 && end > start + 2) {
          final inner = s.substring(start + 2, end);
          final parts = inner.split(',');
          return parts.map((p) {
            final nums = p.trim().split(RegExp(r'\s+'));
            final lon = double.tryParse(nums[0]) ?? 0;
            final lat = double.tryParse(nums.length > 1 ? nums[1] : '0') ?? 0;
            return LatLng(lat, lon);
          }).toList();
        }
      }

      // GeoJSON (string): ... [[lon,lat], [lon,lat], ...]
      if (s.startsWith('[')) {
        final matches = RegExp(r'\[([^\[\]]+)\]').allMatches(s);
        final list = <LatLng>[];
        for (final m in matches) {
          final pair = m.group(1)!.split(',');
          if (pair.length >= 2) {
            final lon = double.tryParse(pair[0]) ?? 0;
            final lat = double.tryParse(pair[1]) ?? 0;
            list.add(LatLng(lat, lon));
          }
        }
        return list;
      }
    }

    // Lista dinámica: [[lon,lat], ...]  o  [{lon:x,lat:y}, ...]
    if (geometry is List) {
      return geometry.map<LatLng>((e) {
        if (e is List && e.length >= 2) {
          final lon = (e[0] as num).toDouble();
          final lat = (e[1] as num).toDouble();
          return LatLng(lat, lon);
        }
        if (e is Map) {
          final lon = (e['lon'] as num?)?.toDouble() ?? 0;
          final lat = (e['lat'] as num?)?.toDouble() ?? 0;
          return LatLng(lat, lon);
        }
        return const LatLng(0, 0);
      }).toList();
    }

    return const [];
  }
}
