import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../explore_controller.dart';

class ExploreMap extends StatelessWidget {
  const ExploreMap({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ExploreController>();

    return GoogleMap(
      mapToolbarEnabled: false,
      zoomControlsEnabled: false,
      myLocationButtonEnabled: true,
      myLocationEnabled: c.myLocationEnabled, // 👈 ya existe en el controller

      initialCameraPosition: c.initialCamera,
      onMapCreated: c.onMapCreated,
      onCameraMove: c.onCameraMove,
      onTap: c.onMapTap,
      onLongPress: c.onMapLongPress,

      markers: c.allMarkers(),
      polygons: c.polygons,

      buildingsEnabled: true,
      compassEnabled: true,
      trafficEnabled: false,
      mapType: MapType.normal,
    );
  }
}
