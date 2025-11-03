import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/explore/explore_controller.dart';

/// Widget para controlar las capas PostGIS en el mapa
class PostgisLayersWidget extends StatelessWidget {
  const PostgisLayersWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreController>(
      builder: (context, controller, child) {
        return SingleChildScrollView(
          child: Container(
            width: 220,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.layers, color: Colors.teal[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Capas PostGIS',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => controller.hidePostgisLayers(),
                      icon: const Icon(Icons.close, size: 20),
                      color: Colors.grey[600],
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Botón Colonias
                _buildLayerButton(
                  context: context,
                  controller: controller,
                  icon: Icons.location_city,
                  color: Colors.blue,
                  title: 'Colonias',
                  subtitle: 'Datos demográficos',
                  isVisible: controller.showPostgisAgebLayer,
                  onToggle: () async {
                    await controller.loadPostgisLayers(
                      showAgeb: !controller.showPostgisAgebLayer,
                      showTransporte: controller.showPostgisTransporteLayer,
                      showRutas: controller.showPostgisRutasLayer,
                      showLineas: controller.showPostgisLineasLayer,
                    );
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Botón Transporte
                _buildLayerButton(
                  context: context,
                  controller: controller,
                  icon: Icons.directions_bus,
                  color: Colors.purple,
                  title: 'Transporte',
                  subtitle: 'Estaciones y rutas',
                  isVisible: controller.showPostgisTransporteLayer,
                  onToggle: () async {
                    await controller.loadPostgisLayers(
                      showAgeb: controller.showPostgisAgebLayer,
                      showTransporte: !controller.showPostgisTransporteLayer,
                      showRutas: controller.showPostgisRutasLayer,
                      showLineas: controller.showPostgisLineasLayer,
                    );
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Botón Rutas
                _buildLayerButton(
                  context: context,
                  controller: controller,
                  icon: Icons.route,
                  color: Colors.orange,
                  title: 'Rutas',
                  subtitle: 'Red de transporte',
                  isVisible: controller.showPostgisRutasLayer,
                  onToggle: () async {
                    await controller.loadPostgisLayers(
                      showAgeb: controller.showPostgisAgebLayer,
                      showTransporte: controller.showPostgisTransporteLayer,
                      showRutas: !controller.showPostgisRutasLayer,
                      showLineas: controller.showPostgisLineasLayer,
                    );
                  },
                ),
                
                const SizedBox(height: 8),
                
                // Botón Líneas
                _buildLayerButton(
                  context: context,
                  controller: controller,
                  icon: Icons.timeline,
                  color: Colors.red,
                  title: 'Líneas',
                  subtitle: 'Transporte masivo',
                  isVisible: controller.showPostgisLineasLayer,
                  onToggle: () async {
                    await controller.loadPostgisLayers(
                      showAgeb: controller.showPostgisAgebLayer,
                      showTransporte: controller.showPostgisTransporteLayer,
                      showRutas: controller.showPostgisRutasLayer,
                      showLineas: !controller.showPostgisLineasLayer,
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLayerButton({
    required BuildContext context,
    required ExploreController controller,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isVisible,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isVisible ? color.withOpacity(0.1) : Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isVisible ? color.withOpacity(0.3) : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isVisible ? color : Colors.grey[400],
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isVisible ? Colors.black87 : Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: isVisible ? color : Colors.grey[400],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

