import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/map_symbols.dart';
import '../features/explore/explore_controller.dart';
import 'glossary_tooltip.dart';

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
                      // Solo ocultar el panel, no las capas
                      // Las capas permanecen visibles en el mapa
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
              _buildLegendItemWithGlossary(
                context: context,
                icon: MapSymbols.denueIcon,
                color: MapSymbols.denueColor,
                title: 'Actividades Económicas',
                subtitle: 'DENUE - INEGI',
                glossaryKey: 'denue',
                isVisible: controller.allMarkers().any((marker) => 
                  marker.markerId.value.startsWith('denue_')),
              ),
              
              const SizedBox(height: 8),
              
              // Marcadores de Delitos
              _buildLegendItem(
                icon: MapSymbols.delitoIcon,
                color: MapSymbols.delitoColor,
                title: 'Delitos',
                subtitle: 'Datos de seguridad',
                isVisible: controller.allMarkers().any((marker) => 
                  marker.markerId.value.startsWith('delito_')),
              ),
              
              const SizedBox(height: 8),
              
              // Marcadores de Google Places
              _buildLegendItem(
                icon: MapSymbols.placesIcon,
                color: MapSymbols.placesColor,
                title: 'Propiedades',
                subtitle: 'Google Places',
                isVisible: controller.showGooglePlacesMarkers,
              ),
              
              const SizedBox(height: 8),
              
              // Marcadores de Rentas
              _buildLegendItem(
                icon: MapSymbols.rentaIcon,
                color: MapSymbols.rentaColor,
                title: 'Rentas',
                subtitle: 'Propiedades en renta',
                isVisible: controller.allMarkers().any(
                  (marker) => marker.markerId.value.startsWith('renta_'),
                ),
              ),
              
              const SizedBox(height: 8),
              
              // Polígonos AGEB
              _buildLegendItemWithGlossary(
                context: context,
                icon: Icons.area_chart,
                color: Colors.orange,
                title: 'Áreas AGEB',
                subtitle: 'Códigos postales',
                glossaryKey: 'ageb',
                isVisible: controller.polygons.isNotEmpty,
              ),
              
              const SizedBox(height: 8),
              
              // Divider para capas PostGIS
              const Divider(),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'Capas PostGIS',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal[700],
                    ),
                  ),
                  const SizedBox(width: 4),
                  GlossaryHelpIcon(
                    termKey: 'postgis',
                    color: Colors.teal[700],
                    size: 14,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Colonias PostGIS
              _buildLegendItemWithGlossary(
                context: context,
                icon: Icons.location_city,
                color: Colors.blue,
                title: 'Colonias',
                subtitle: 'Datos demográficos',
                glossaryKey: 'densidad_poblacional',
                isVisible: controller.showPostgisAgebLayer,
              ),
              
              const SizedBox(height: 8),
              
              // Estaciones Transporte
              _buildLegendItem(
                icon: MapSymbols.stationIcon,
                color: MapSymbols.stationColor,
                title: 'Estaciones',
                subtitle: 'Transporte masivo',
                isVisible: controller.showPostgisTransporteLayer,
              ),
              
              const SizedBox(height: 8),
              
              // Rutas
              _buildLegendItem(
                icon: Icons.route,
                color: Colors.orange,
                title: 'Rutas',
                subtitle: 'Red de transporte',
                isVisible: controller.showPostgisRutasLayer,
              ),
              
              const SizedBox(height: 8),
              
              // Líneas
              _buildLegendItem(
                icon: Icons.timeline,
                color: Colors.red,
                title: 'Líneas',
                subtitle: 'Transporte masivo',
                isVisible: controller.showPostgisLineasLayer,
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
          // Símbolo estilo ArcGIS: círculo con icono dentro
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: isVisible ? color : Colors.grey[400],
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 18,
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

  Widget _buildLegendItemWithGlossary({
    required BuildContext context,
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String glossaryKey,
    required bool isVisible,
  }) {
    return GestureDetector(
      onTap: () => showGlossaryModal(context, glossaryKey),
      child: Container(
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
            // Símbolo estilo ArcGIS
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isVisible ? color : Colors.grey[400],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isVisible ? Colors.black87 : Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GlossaryHelpIcon(
                        termKey: glossaryKey,
                        color: isVisible ? color : Colors.grey[400],
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
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
              child: Icon(
                isVisible ? Icons.visibility : Icons.visibility_off,
                color: Colors.white,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
