import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../explore_controller.dart';

class ExploreMap extends StatelessWidget {
  const ExploreMap({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ExploreController>();
    
    // Debug: Log polylines
    print('🗺️ ExploreMap build: ${c.polylines.length} polylines');
    print('🗺️ Rutas: ${c.polylines.where((p) => p.polylineId.value.startsWith('postgis_ruta_')).length}');
    print('🗺️ Líneas: ${c.polylines.where((p) => p.polylineId.value.startsWith('postgis_linea_')).length}');

    return GoogleMap(
      mapToolbarEnabled: true,
      zoomControlsEnabled: true,
      myLocationButtonEnabled: true,
      myLocationEnabled: c.myLocationEnabled, // 👈 ya existe en el controller

      initialCameraPosition: c.initialCamera,
      onMapCreated: c.onMapCreated,
      onCameraMove: c.onCameraMove,
      onTap: c.onMapTap,
      onLongPress: c.onMapLongPress,

      markers: c.allMarkers(),
      polygons: c.getPolygonsWithConcentration(),
      polylines: c.polylines,

      buildingsEnabled: true,
      compassEnabled: true,
      trafficEnabled: false,
      mapType: MapType.normal,
    );
  }
}
