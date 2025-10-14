import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../features/explore/explore_controller.dart';

class Mapbox3DMap extends StatefulWidget {
  final Function(MapboxMap) onMapCreated;

  const Mapbox3DMap({
    Key? key,
    required this.onMapCreated,
  }) : super(key: key);

  @override
  State<Mapbox3DMap> createState() => _Mapbox3DMapState();
}

class _Mapbox3DMapState extends State<Mapbox3DMap> {
  MapboxMap? mapboxMap;

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreController>(
      builder: (context, exploreController, child) {
        return Stack(
          children: [
            MapWidget(
              key: const ValueKey("mapWidget"),
              cameraOptions: CameraOptions(
                center: Point(coordinates: Position(-103.3450723, 20.6599162)), // Guadalajara
                zoom: 12.0,
                pitch: 60.0, // Inclinación para vista 3D
                bearing: 0.0,
              ),
              styleUri: MapboxStyles.MAPBOX_STREETS,
              onMapCreated: (MapboxMap map) {
                setState(() {
                  mapboxMap = map;
                });
                widget.onMapCreated(map);
                _setup3DMap(map);
                _addPolygonsToMap(map, exploreController);
              },
            ),
            // Controles de zoom personalizados
            Positioned(
              right: 16,
              top: 100,
              child: Column(
                children: [
                  FloatingActionButton(
                    mini: true,
                    onPressed: () => _zoomIn(),
                    child: const Icon(Icons.add),
                  ),
                  const SizedBox(height: 8),
                  FloatingActionButton(
                    mini: true,
                    onPressed: () => _zoomOut(),
                    child: const Icon(Icons.remove),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _setup3DMap(MapboxMap map) {
    // Configurar el mapa para vista 3D
    // Nota: La API de Mapbox ha cambiado, estos métodos pueden necesitar ajustes
    // según la versión específica del plugin
    
    try {
      // Habilitar edificios 3D
      map.style.setStyleLayerProperty(
        'building',
        'visibility',
        'visible',
      );

      // Configurar estilo de edificios 3D
      map.style.setStyleLayerProperty(
        'building',
        'fill-extrusion-height',
        10.0,
      );

      map.style.setStyleLayerProperty(
        'building',
        'fill-extrusion-base',
        0.0,
      );

      map.style.setStyleLayerProperty(
        'building',
        'fill-extrusion-color',
        '#aaa',
      );
    } catch (e) {
      print('Error configuring 3D map: $e');
      // Continuar sin configuración 3D si hay errores
    }
  }

  void _addPolygonsToMap(MapboxMap map, ExploreController controller) {
    try {
      final polygons3D = controller.getPolygonsFor3D();
      
      if (polygons3D.isEmpty) {
        print('🗺️ No hay polígonos para mostrar en 3D');
        return;
      }

      print('🗺️ Agregando ${polygons3D.length} polígonos al mapa 3D');

      // Crear fuente GeoJSON con los polígonos
      final geoJsonSource = GeoJsonSource(
        id: 'ageb-polygons',
        data: jsonEncode({
          'type': 'FeatureCollection',
          'features': polygons3D,
        }),
      );

      // Agregar la fuente al mapa
      map.style.addSource(geoJsonSource);

      // Crear capa de relleno con extrusión 3D
      final fillLayer = FillLayer(
        id: 'ageb-fill',
        sourceId: 'ageb-polygons',
        fillColor: 0xFF00BCD4,
        fillOpacity: 0.6,
      );

      // Crear capa de extrusión 3D
      final extrusionLayer = FillExtrusionLayer(
        id: 'ageb-extrusion',
        sourceId: 'ageb-polygons',
        fillExtrusionColor: 0xFF00BCD4,
        fillExtrusionOpacity: 0.8,
        fillExtrusionHeight: 50.0,
        fillExtrusionBase: 0.0,
      );

      // Crear capa de borde
      final lineLayer = LineLayer(
        id: 'ageb-line',
        sourceId: 'ageb-polygons',
        lineColor: 0xFF00BCD4,
        lineWidth: 3.0,
      );

      // Agregar las capas al mapa
      map.style.addLayer(fillLayer);
      map.style.addLayer(extrusionLayer);
      map.style.addLayer(lineLayer);

      print('✅ Polígonos agregados exitosamente al mapa 3D');

    } catch (e) {
      print('❌ Error adding polygons to 3D map: $e');
    }
  }

  void _zoomIn() {
    if (mapboxMap != null) {
      // Obtener el zoom actual y aumentarlo
      mapboxMap!.getCameraState().then((cameraState) {
        final newZoom = (cameraState.zoom + 1).clamp(0.0, 20.0);
        mapboxMap!.easeTo(
          CameraOptions(zoom: newZoom),
          MapAnimationOptions(duration: 300),
        );
      });
    }
  }

  void _zoomOut() {
    if (mapboxMap != null) {
      // Obtener el zoom actual y disminuirlo
      mapboxMap!.getCameraState().then((cameraState) {
        final newZoom = (cameraState.zoom - 1).clamp(0.0, 20.0);
        mapboxMap!.easeTo(
          CameraOptions(zoom: newZoom),
          MapAnimationOptions(duration: 300),
        );
      });
    }
  }

  @override
  void dispose() {
    mapboxMap?.dispose();
    super.dispose();
  }
}
