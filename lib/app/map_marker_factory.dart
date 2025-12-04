import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/material.dart';
import '../utils/marker_icon_painter.dart';
import 'map_symbols.dart';

/// Factory para crear marcadores personalizados estilo ArcGIS
class MapMarkerFactory {
  /// Crea marcador para actividades económicas DENUE
  static Future<BitmapDescriptor> createDenueMarker() async {
    return MapSymbols.getCustomIcon('denue', () async {
      return MarkerIconPainter.createCustomMarkerIcon(
        icon: MapSymbols.denueIcon,
        backgroundColor: MapSymbols.denueColor,
        iconColor: Colors.white,
        size: 100,
        iconSize: 50,
      );
    });
  }

  /// Crea marcador para delitos
  static Future<BitmapDescriptor> createDelitoMarker() async {
    return MapSymbols.getCustomIcon('delito', () async {
      return MarkerIconPainter.createCustomMarkerIcon(
        icon: MapSymbols.delitoIcon,
        backgroundColor: MapSymbols.delitoColor,
        iconColor: Colors.white,
        size: 100,
        iconSize: 50,
      );
    });
  }

  /// Crea marcador para propiedades (Google Places)
  static Future<BitmapDescriptor> createPlacesMarker() async {
    return MapSymbols.getCustomIcon('places', () async {
      return MarkerIconPainter.createCustomMarkerIcon(
        icon: MapSymbols.placesIcon,
        backgroundColor: MapSymbols.placesColor,
        iconColor: Colors.white,
        size: 100,
        iconSize: 50,
      );
    });
  }

  /// Crea marcador para rentas
  static Future<BitmapDescriptor> createRentaMarker() async {
    return MapSymbols.getCustomIcon('renta', () async {
      return MarkerIconPainter.createCustomMarkerIcon(
        icon: MapSymbols.rentaIcon,
        backgroundColor: MapSymbols.rentaColor,
        iconColor: Colors.white,
        size: 100,
        iconSize: 50,
      );
    });
  }

  /// Crea marcador para comercios
  static Future<BitmapDescriptor> createCommercialMarker() async {
    return MapSymbols.getCustomIcon('commercial', () async {
      return MarkerIconPainter.createCustomMarkerIcon(
        icon: MapSymbols.commercialIcon,
        backgroundColor: MapSymbols.commercialColor,
        iconColor: Colors.white,
        size: 100,
        iconSize: 50,
      );
    });
  }

  /// Crea marcador para estaciones de transporte
  static Future<BitmapDescriptor> createStationMarker() async {
    return MapSymbols.getCustomIcon('station', () async {
      return MarkerIconPainter.createCustomMarkerIcon(
        icon: MapSymbols.stationIcon,
        backgroundColor: MapSymbols.stationColor,
        iconColor: Colors.white,
        size: 100,
        iconSize: 50,
      );
    });
  }

  /// Crea marcador de selección
  static Future<BitmapDescriptor> createSelectionMarker() async {
    return MapSymbols.getCustomIcon('selection', () async {
      return MarkerIconPainter.createCustomMarkerIcon(
        icon: MapSymbols.selectionIcon,
        backgroundColor: Colors.orange,
        iconColor: Colors.white,
        size: 100,
        iconSize: 50,
        borderColor: Colors.white,
      );
    });
  }

  /// Crea marcador con badge de número (para clusters)
  static Future<BitmapDescriptor> createMarkerWithBadge({
    required String type,
    required int count,
  }) async {
    final key = '${type}_badge_$count';
    return MapSymbols.getCustomIcon(key, () async {
      IconData icon;
      Color backgroundColor;

      switch (type) {
        case 'denue':
          icon = MapSymbols.denueIcon;
          backgroundColor = MapSymbols.denueColor;
          break;
        case 'delito':
          icon = MapSymbols.delitoIcon;
          backgroundColor = MapSymbols.delitoColor;
          break;
        case 'places':
          icon = MapSymbols.placesIcon;
          backgroundColor = MapSymbols.placesColor;
          break;
        case 'renta':
          icon = MapSymbols.rentaIcon;
          backgroundColor = MapSymbols.rentaColor;
          break;
        default:
          icon = Icons.place;
          backgroundColor = Colors.grey;
      }

      return MarkerIconPainter.createMarkerWithBadge(
        icon: icon,
        backgroundColor: backgroundColor,
        iconColor: Colors.white,
        badgeNumber: count,
        size: 100,
      );
    });
  }
}

