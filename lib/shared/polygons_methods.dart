// lib/shared/polygons_methods.dart
import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Parser robusto: acepta GeoJSON (Polygon/MultiPolygon) o WKT POLYGON.
/// Tu campo MySQL `geometry` debe venir como String.
class PolygonsMethods {
  /// Método del proyecto anterior que funciona
  List<LatLng> geometry_data(dynamic data) {
    List<LatLng> polygonCoords = [];
    
    try {
      // Si data es un String (desde MySQL), usarlo directamente
      String geometryString;
      if (data is String) {
        geometryString = data;
      } else if (data is List && data.isNotEmpty) {
        geometryString = data[0].toString();
      } else {
        print('❌ geometry_data: formato de datos no soportado: ${data.runtimeType}');
        return polygonCoords;
      }
      
      print('🔍 geometry_data procesando: ${geometryString.substring(0, geometryString.length > 100 ? 100 : geometryString.length)}...');
      
      var new_list = geometryString.replaceAll(" ", "").split(",");
      print('🔍 geometry_data split en ${new_list.length} partes');

      while (new_list.isNotEmpty) {
        if (new_list.length < 2) break; // Necesitamos al menos 2 valores (lat, lon)
        
        var lat = double.parse(new_list.removeLast());
        var lon = double.parse(new_list.removeLast());
        polygonCoords.add(LatLng(lat, lon));
      }
      
      print('✅ geometry_data exitoso: ${polygonCoords.length} puntos');
    } catch (e) {
      print('❌ geometry_data error: $e');
    }

    return polygonCoords;
  }

  List<LatLng> geometryToLatLngList(dynamic raw) {
    // `raw` puede venir como List, Map o String (desde MySQL)
    if (raw == null) return const [];

    if (raw is List) {
      // ya viene como lista de pares [lng, lat] o [lat, lng]
      return _fromList(raw);
    }

    if (raw is Map) {
      // GeoJSON ya decodificado
      return _fromGeoJsonMap(raw);
    }

    if (raw is String) {
      // ¿GeoJSON String?
      try {
        final decoded = json.decode(raw);
        if (decoded is Map) {
          return _fromGeoJsonMap(decoded);
        }
      } catch (_) {
        // no era JSON → podría ser WKT
      }
      // WKT: POLYGON((lng lat, lng lat, ...))
      return _fromWkt(raw);
    }

    return const [];
  }

  // ---- Helpers ----

  List<LatLng> _fromList(List data) {
    final out = <LatLng>[];
    for (final e in data) {
      if (e is List && e.length >= 2) {
        // Asumimos [lng, lat] (GeoJSON) → invertir
        final a = (e[0] as num).toDouble();
        final b = (e[1] as num).toDouble();
        // detecta si parece [lat, lng]
        final isLatLngOrder = a.abs() <= 90 && b.abs() <= 180;
        out.add(isLatLngOrder ? LatLng(a, b) : LatLng(b, a));
      }
    }
    return out;
  }

  List<LatLng> _fromGeoJsonMap(Map g) {
    final type = g['type']?.toString().toLowerCase();
    if (type == 'polygon') {
      final coords = g['coordinates'];
      return _ringToLatLng(coords?.first);
    } else if (type == 'multipolygon') {
      // usa el primer polígono del multipolígono
      final polys = g['coordinates'];
      if (polys is List && polys.isNotEmpty) {
        return _ringToLatLng(polys.first.first);
      }
    }
    return const [];
    }

  List<LatLng> _ringToLatLng(dynamic ring) {
    if (ring is! List) return const [];
    final out = <LatLng>[];
    for (final c in ring) {
      if (c is List && c.length >= 2) {
        final lng = (c[0] as num).toDouble();
        final lat = (c[1] as num).toDouble();
        out.add(LatLng(lat, lng));
      }
    }
    return out;
  }

  List<LatLng> _fromWkt(String wkt) {
    final s = wkt.trim();
    if (!s.toUpperCase().startsWith('POLYGON')) return const [];
    final inner = s.substring(s.indexOf(('(')) + 1, s.lastIndexOf(')'));
    // soporta POLYGON((...),(...)) → toma el primer anillo
    final firstRing = inner.split('),(').first.replaceAll('(', '').replaceAll(')', '');
    final pairs = firstRing.split(',');
    final out = <LatLng>[];
    for (final p in pairs) {
      final parts = p.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final lng = double.tryParse(parts[0]);
        final lat = double.tryParse(parts[1]);
        if (lng != null && lat != null) out.add(LatLng(lat, lng));
      }
    }
    return out;
  }
}
