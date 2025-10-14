import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxPage extends StatefulWidget {
  const MapboxPage({super.key});

  @override
  State<MapboxPage> createState() => _MapboxPageState();
}

class _MapboxPageState extends State<MapboxPage> {
  MapboxMap? _map;

  final String _styleUri = const String.fromEnvironment(
    'STYLE_URI',
    defaultValue: 'mapbox://styles/kevinroberto/cmgharq80006y01ryg3vl8zc5',
  );

  final CameraOptions _camera = CameraOptions(
    center: Point(coordinates: Position(-103.349609, 20.659699)),
    zoom: 13.0,
    pitch: 60.0,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mapa 3D')),
      body: MapWidget(
        key: const ValueKey('mapbox3d'),
        styleUri: _styleUri,
        cameraOptions: _camera,
        onMapCreated: (m) => _map = m,
      ),
    );
  }

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }
}
