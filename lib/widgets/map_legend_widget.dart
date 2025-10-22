import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../features/explore/explore_controller.dart';

class MapLegendWidget extends StatelessWidget {
  const MapLegendWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreController>(
      builder: (context, controller, child) {
        return Container(
          width: 220,
          margin: const EdgeInsets.all(12),
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
                  Icon(Icons.legend_toggle, color: Colors.grey[700], size: 20),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Leyenda del Mapa',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // Cerrar la leyenda
                      controller.hideConcentrationLayer();
                    },
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
              
              // Marcadores DENUE (Actividades Económicas)
              _buildLegendItem(
                icon: Icons.business,
                color: Colors.blue,
                title: 'Actividades Económicas',
                subtitle: 'DENUE - INEGI',
                isVisible: controller.allMarkers().any((marker) => 
                  marker.markerId.value.startsWith('denue_')),
              ),
              
              const SizedBox(height: 8),
              
              // Marcadores de Delitos
              _buildLegendItem(
                icon: Icons.warning,
                color: Colors.red,
                title: 'Delitos',
                subtitle: 'Datos de seguridad',
                isVisible: controller.allMarkers().any((marker) => 
                  marker.markerId.value.startsWith('delito_')),
              ),
              
              const SizedBox(height: 8),
              
              // Marcadores de Google Places
              _buildLegendItem(
                icon: Icons.home,
                color: Colors.green,
                title: 'Propiedades',
                subtitle: 'Google Places',
                isVisible: controller.showGooglePlacesMarkers,
              ),
              
              const SizedBox(height: 8),
              
              // Polígonos AGEB
              _buildLegendItem(
                icon: Icons.area_chart,
                color: Colors.orange,
                title: 'Áreas AGEB',
                subtitle: 'Códigos postales',
                isVisible: controller.polygons.isNotEmpty,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isVisible,
    VoidCallback? onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
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
            child: Icon(
              icon,
              color: Colors.white,
              size: 16,
            ),
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
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isVisible ? color : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: isVisible
                ? const Icon(
                    Icons.visibility,
                    color: Colors.white,
                    size: 14,
                  )
                : const Icon(
                    Icons.visibility_off,
                    color: Colors.white,
                    size: 14,
                  ),
          ),
        ],
      ),
    );
  }
}
