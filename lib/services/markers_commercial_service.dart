import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MarkersCommercialService {
  final List<Map<String, dynamic>> commercialData;

  MarkersCommercialService(this.commercialData);

  /// Crea marcadores comerciales basado en los datos
  List<Marker> createCommercialMarkers() {
    final List<Marker> markers = [];

    for (int i = 0; i < commercialData.length; i++) {
      final data = commercialData[i];
      
      // Crear marcador
      final markerId = MarkerId('commercial_$i');
      final marker = Marker(
        markerId: markerId,
        position: LatLng(
          double.parse(data['lat'] ?? '0'),
          double.parse(data['lon'] ?? '0'),
        ),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        infoWindow: InfoWindow(
          title: data['nombre'] ?? 'Sin nombre',
          snippet: data['descripcion'] ?? '',
        ),
      );

      markers.add(marker);
    }

    return markers;
  }
}
