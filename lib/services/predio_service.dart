import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';

// IMPORT CORRECTO (antes apuntaba a resourses/exceReader.dart)
import 'excel_reader.dart';

class PredioInfo {
  final String cuentaCatastral;
  final String usoDeSuelo;
  final double superficie;
  final String domicilio;

  PredioInfo({
    required this.cuentaCatastral,
    required this.usoDeSuelo,
    required this.superficie,
    required this.domicilio,
  });
}

class PredioService {
  /// Demo: resuelve un predio por coordenadas.
  /// Cuando tengas el endpoint real de Visor Urbano, sustitúyelo aquí.
  Future<PredioInfo?> fetchPredioByLatLng(LatLng p) async {
    // Si necesitas UTM de tu ExcelReader, esto ya compila con el import correcto.
    try {
      await ExcelReader.modifyLatAndLon(p.latitude, p.longitude);
    } catch (_) {
      // Silencioso: si tu ExcelReader no implementa el método no truena
    }

    // Simulación de respuesta
    final rnd = Random(p.latitude.hashCode ^ p.longitude.hashCode);
    return PredioInfo(
      cuentaCatastral: 'GUAD-${rnd.nextInt(999999).toString().padLeft(6, '0')}',
      usoDeSuelo: ['Habitacional', 'Comercial', 'Mixto'][rnd.nextInt(3)],
      superficie: 80 + rnd.nextInt(300).toDouble(),
      domicilio: 'Calle Ejemplo #${10 + rnd.nextInt(999)}, Guadalajara, Jal.',
    );
  }
}
