import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../app/map_symbols.dart';

class MarkersCommercialService {
  final List<Map<String, dynamic>> commercialData;

  MarkersCommercialService(this.commercialData);

  /// Crea marcadores comerciales basado en los datos con iconos personalizados estilo ArcGIS
  Future<List<Marker>> createCommercialMarkers() async {
    final List<Marker> markers = [];
    
    // Crear icono personalizado estilo ArcGIS para Comercios
    final commercialIcon = await MapSymbols.getCommercialMarker();

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
        icon: commercialIcon,
        anchor: Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: '${MapSymbols.commercialEmoji} ${data['nombre'] ?? 'Sin nombre'}',
          snippet: data['descripcion'] ?? '',
        ),
      );

      markers.add(marker);
    }

    return markers;
  }
}
