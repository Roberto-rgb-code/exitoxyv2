import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../services/custom_marker_service.dart';

/// Configuración centralizada de simbología para el mapa de exitoxy.
///
/// La idea es que **cada capa** (actividades económicas, delitos, rentas, etc.)
/// tenga un color, icono y emoji consistentes tanto en:
/// - Marcadores de Google Maps (estilo ArcGIS: círculos con iconos)
/// - Leyenda del mapa
/// - Títulos de ventanas de información
class MapSymbols {
  static final Map<String, BitmapDescriptor> _iconCache = {};
  // ===========================
  // Actividades Económicas (DENUE)
  // ===========================
  static const double denueHue = BitmapDescriptor.hueBlue;
  static const IconData denueIcon = Icons.business;
  static const String denueEmoji = '🏢';

  // ===========================
  // Delitos / Seguridad
  // ===========================
  static const double delitoHue = BitmapDescriptor.hueRed;
  static const IconData delitoIcon = Icons.warning;
  static const String delitoEmoji = '⚠️';

  // ===========================
  // Propiedades (Google Places)
  // ===========================
  static const double placesHue = BitmapDescriptor.hueGreen;
  static const IconData placesIcon = Icons.home;
  static const String placesEmoji = '🏠';

  // ===========================
  // Rentas (PostgreSQL / datos finales)
  // ===========================
  static const double rentaHue = BitmapDescriptor.hueViolet;
  static const IconData rentaIcon = Icons.home_work;
  static const String rentaEmoji = '📦';

  // ===========================
  // Comercios MySQL (tabla comercios)
  // ===========================
  static const double commercialHue = BitmapDescriptor.hueAzure;
  static const IconData commercialIcon = Icons.store_mall_directory;
  static const String commercialEmoji = '🏬';

  // ===========================
  // Estaciones de transporte (PostGIS)
  // ===========================
  static const double stationHue = BitmapDescriptor.hueViolet;
  static const IconData stationIcon = Icons.directions_bus;
  static const String stationEmoji = '🚉';

  // ===========================
  // Marcador de selección de zona
  // ===========================
  static const double selectionHue = BitmapDescriptor.hueOrange;
  static const IconData selectionIcon = Icons.location_on;
  static const String selectionEmoji = '📍';

  // ===========================
  // Colores auxiliares para leyendas
  // ===========================
  static const Color denueColor = Colors.blue;
  static const Color delitoColor = Colors.red;
  static const Color placesColor = Colors.green;
  static const Color rentaColor = Colors.purple;
  static const Color commercialColor = Colors.blueAccent;
  static const Color stationColor = Colors.deepPurple;

  /// Obtiene o crea un icono personalizado estilo ArcGIS desde el cache
  static Future<BitmapDescriptor> getCustomIcon(
    String key,
    Future<BitmapDescriptor> Function() creator,
  ) async {
    return CustomMarkerService.getMarker(key, creator);
  }

  /// Limpia el cache de iconos (útil para liberar memoria)
  static void clearIconCache() {
    CustomMarkerService.clearCache();
    _iconCache.clear();
  }

  // ===========================
  // Métodos helper para obtener marcadores personalizados
  // ===========================

  /// Obtiene marcador DENUE (círculo azul con icono de tienda)
  static Future<BitmapDescriptor> getDenueMarker() async {
    return getCustomIcon('denue', CustomMarkerService.createDenueMarker);
  }

  /// Obtiene marcador de Delito (círculo rojo con icono de alerta)
  static Future<BitmapDescriptor> getDelitoMarker() async {
    return getCustomIcon('delito', CustomMarkerService.createDelitoMarker);
  }

  /// Obtiene marcador de Propiedad (círculo verde con icono de casa)
  static Future<BitmapDescriptor> getPlaceMarker() async {
    return getCustomIcon('place', CustomMarkerService.createPlaceMarker);
  }

  /// Obtiene marcador de Renta (círculo morado con icono de casa)
  static Future<BitmapDescriptor> getRentaMarker() async {
    return getCustomIcon('renta', CustomMarkerService.createRentaMarker);
  }

  /// Obtiene marcador de Comercio (círculo azul claro con icono de tienda)
  static Future<BitmapDescriptor> getCommercialMarker() async {
    return getCustomIcon('commercial', CustomMarkerService.createCommercialMarker);
  }

  /// Obtiene marcador de Estación (círculo morado oscuro con icono de bus)
  static Future<BitmapDescriptor> getStationMarker() async {
    return getCustomIcon('station', CustomMarkerService.createStationMarker);
  }

  /// Obtiene marcador de Selección (círculo naranja con icono de marcador)
  static Future<BitmapDescriptor> getSelectionMarker() async {
    return getCustomIcon('selection', CustomMarkerService.createSelectionMarker);
  }
}


