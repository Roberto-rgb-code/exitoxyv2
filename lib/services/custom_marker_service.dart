import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

/// Servicio para crear marcadores personalizados estilo ArcGIS
/// (círculos con iconos dentro, como los símbolos gubernamentales)
class CustomMarkerService {
  /// Crea un BitmapDescriptor desde un widget personalizado
  static Future<BitmapDescriptor> createCustomMarker({
    required Color backgroundColor,
    required IconData icon,
    required Color iconColor,
    double size = 48.0,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..style = PaintingStyle.fill;

    // Dibujar círculo de fondo
    paint.color = backgroundColor;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 2,
      paint,
    );

    // Dibujar borde blanco
    paint
      ..style = PaintingStyle.stroke
      ..color = Colors.white
      ..strokeWidth = 2.0;
    canvas.drawCircle(
      Offset(size / 2, size / 2),
      size / 2 - 2,
      paint,
    );

    // Dibujar icono usando TextPainter con soporte para Material Design Icons
    final textPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: 24.0,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: iconColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    textPainter.layout(minWidth: 0, maxWidth: size);
    textPainter.paint(
      canvas,
      Offset(
        (size - textPainter.width) / 2,
        (size - textPainter.height) / 2 - 2, // Ajuste vertical para centrar mejor
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  /// Crea marcador para DENUE (Actividades Económicas)
  static Future<BitmapDescriptor> createDenueMarker() async {
    return createCustomMarker(
      backgroundColor: const Color(0xFF2196F3), // Azul
      icon: MdiIcons.store,
      iconColor: Colors.white,
    );
  }

  /// Crea marcador para Delitos
  static Future<BitmapDescriptor> createDelitoMarker() async {
    return createCustomMarker(
      backgroundColor: const Color(0xFFF44336), // Rojo
      icon: MdiIcons.alertCircle,
      iconColor: Colors.white,
    );
  }

  /// Crea marcador para Propiedades (Google Places)
  static Future<BitmapDescriptor> createPlaceMarker() async {
    return createCustomMarker(
      backgroundColor: const Color(0xFF4CAF50), // Verde
      icon: MdiIcons.home,
      iconColor: Colors.white,
    );
  }

  /// Crea marcador para Rentas
  static Future<BitmapDescriptor> createRentaMarker() async {
    return createCustomMarker(
      backgroundColor: const Color(0xFF9C27B0), // Morado
      icon: MdiIcons.homeVariant,
      iconColor: Colors.white,
    );
  }

  /// Crea marcador para Comercios
  static Future<BitmapDescriptor> createCommercialMarker() async {
    return createCustomMarker(
      backgroundColor: const Color(0xFF03A9F4), // Azul claro
      icon: MdiIcons.storefront,
      iconColor: Colors.white,
    );
  }

  /// Crea marcador para Estaciones de Transporte
  static Future<BitmapDescriptor> createStationMarker() async {
    return createCustomMarker(
      backgroundColor: const Color(0xFF7B1FA2), // Morado oscuro
      icon: MdiIcons.bus,
      iconColor: Colors.white,
    );
  }

  /// Crea marcador de selección
  static Future<BitmapDescriptor> createSelectionMarker() async {
    return createCustomMarker(
      backgroundColor: const Color(0xFFFF9800), // Naranja
      icon: MdiIcons.mapMarker,
      iconColor: Colors.white,
    );
  }

  /// Cache de marcadores para evitar recrearlos
  static final Map<String, BitmapDescriptor> _cache = {};

  /// Obtiene un marcador desde cache o lo crea
  static Future<BitmapDescriptor> getMarker(String key, Future<BitmapDescriptor> Function() creator) async {
    if (_cache.containsKey(key)) {
      return _cache[key]!;
    }
    final marker = await creator();
    _cache[key] = marker;
    return marker;
  }

  /// Limpia el cache
  static void clearCache() {
    _cache.clear();
  }
}

