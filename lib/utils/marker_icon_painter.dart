import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Utilidad para crear marcadores personalizados estilo ArcGIS con iconos circulares
class MarkerIconPainter {
  /// Crea un BitmapDescriptor personalizado con un ícono circular estilo ArcGIS
  static Future<BitmapDescriptor> createCustomMarkerIcon({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    double size = 120,
    double iconSize = 60,
    bool addShadow = true,
    bool addBorder = true,
    Color? borderColor,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint();

    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 10;

    // Sombra
    if (addShadow) {
      paint
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center + const Offset(0, 4), radius, paint);
    }

    // Círculo de fondo
    paint
      ..color = backgroundColor
      ..maskFilter = null
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paint);

    // Borde
    if (addBorder) {
      paint
        ..color = borderColor ?? Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4;
      canvas.drawCircle(center, radius, paint);
    }

    // Ícono
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );
    textPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: iconSize,
        fontFamily: icon.fontFamily,
        color: iconColor,
        fontWeight: FontWeight.w400,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    // Convertir a imagen
    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }

  /// Crea un marcador con badge de número (para clusters o contadores)
  static Future<BitmapDescriptor> createMarkerWithBadge({
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required int badgeNumber,
    Color badgeColor = Colors.red,
    Color badgeTextColor = Colors.white,
    double size = 120,
  }) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    final paint = Paint();

    final center = Offset(size / 2, size / 2);
    final radius = size / 2 - 10;

    // Círculo principal
    paint
      ..color = backgroundColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, paint);

    // Borde blanco
    paint
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawCircle(center, radius, paint);

    // Ícono
    final iconPainter = TextPainter(textDirection: TextDirection.ltr);
    iconPainter.text = TextSpan(
      text: String.fromCharCode(icon.codePoint),
      style: TextStyle(
        fontSize: 50,
        fontFamily: icon.fontFamily,
        color: iconColor,
      ),
    );
    iconPainter.layout();
    iconPainter.paint(
      canvas,
      Offset(
        center.dx - iconPainter.width / 2,
        center.dy - iconPainter.height / 2,
      ),
    );

    // Badge con número
    if (badgeNumber > 0) {
      final badgeRadius = 20.0;
      final badgeCenter = Offset(size - badgeRadius - 5, badgeRadius + 5);

      // Círculo del badge
      paint
        ..color = badgeColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(badgeCenter, badgeRadius, paint);

      // Borde del badge
      paint
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(badgeCenter, badgeRadius, paint);

      // Número del badge
      final badgeText = badgeNumber > 99 ? '99+' : badgeNumber.toString();
      final badgePainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      badgePainter.text = TextSpan(
        text: badgeText,
        style: TextStyle(
          fontSize: badgeNumber > 99 ? 12 : 14,
          fontWeight: FontWeight.bold,
          color: badgeTextColor,
        ),
      );
      badgePainter.layout();
      badgePainter.paint(
        canvas,
        Offset(
          badgeCenter.dx - badgePainter.width / 2,
          badgeCenter.dy - badgePainter.height / 2,
        ),
      );
    }

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);

    return BitmapDescriptor.fromBytes(bytes!.buffer.asUint8List());
  }
}

