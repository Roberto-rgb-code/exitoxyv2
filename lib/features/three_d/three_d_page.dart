import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import '../explore/explore_controller.dart';
import '../../widgets/mapbox_3d_map.dart';

class ThreeDPage extends StatefulWidget {
  const ThreeDPage({super.key});

  @override
  State<ThreeDPage> createState() => _ThreeDPageState();
}

class _ThreeDPageState extends State<ThreeDPage> {
  MapboxMap? mapboxMap;

  @override
  Widget build(BuildContext context) {
    final exploreController = context.watch<ExploreController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vista 3D'),
        actions: [
          if (exploreController.showConcentrationLayer)
            IconButton(
              icon: const Icon(Icons.layers),
              onPressed: () => _showConcentrationInfo(context, exploreController),
            ),
        ],
      ),
      body: Stack(
        children: [
          // Mapa 3D de Mapbox
          Mapbox3DMap(
            onMapCreated: (map) {
              setState(() {
                mapboxMap = map;
              });
              _loadDataTo3DMap(exploreController);
            },
          ),
          
          // Información de concentración si está disponible
          if (exploreController.showConcentrationLayer)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: _buildConcentrationInfoCard(exploreController),
            ),
          
          // Botón para sincronizar con vista 2D
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              onPressed: () => _syncWith2DView(exploreController),
              child: const Icon(Icons.sync),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConcentrationInfoCard(ExploreController controller) {
    if (controller.currentConcentration == null) return const SizedBox.shrink();

    final result = controller.currentConcentration!;
    final color = Color(result.color);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: color),
                const SizedBox(width: 8),
                Text(
                  'Análisis de Concentración',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetric('HHI', result.hhi.toStringAsFixed(0)),
                _buildMetric('CR4', '${result.cr4.toStringAsFixed(1)}%'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color),
                  ),
                  child: Text(
                    _getLevelLabel(result.level),
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  String _getLevelLabel(String level) {
    switch (level) {
      case 'low': return 'Baja';
      case 'moderate': return 'Moderada';
      case 'high': return 'Alta';
      case 'veryHigh': return 'Muy alta';
      default: return '—';
    }
  }

  void _loadDataTo3DMap(ExploreController controller) {
    if (mapboxMap == null) return;

    // Aquí cargarías los datos del controller al mapa 3D
    // Por ejemplo, polígonos, marcadores, etc.
    
    // Ejemplo de cómo podrías agregar un marcador 3D
    if (controller.lastPoint != null) {
      // mapboxMap!.annotations.createPointAnnotationManager().then((manager) {
      //   manager.create(PointAnnotationOptions(
      //     geometry: Point(coordinates: Position(
      //       controller.lastPoint!.longitude,
      //       controller.lastPoint!.latitude,
      //     )),
      //   ));
      // });
    }
  }

  void _syncWith2DView(ExploreController controller) {
    // Sincronizar la vista 3D con los datos de la vista 2D
    _loadDataTo3DMap(controller);
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Vista 3D sincronizada con datos actuales'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showConcentrationInfo(BuildContext context, ExploreController controller) {
    if (controller.currentConcentration == null) return;

    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Análisis de Concentración 3D',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            // Aquí podrías mostrar más detalles del análisis
            Text('Esta vista 3D muestra el análisis de concentración en una perspectiva tridimensional.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      ),
    );
  }
}
