import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'explore_controller.dart';
import 'map/explore_map.dart';
import 'widgets/activity_prompt.dart';
import '../../widgets/custom_info_window.dart';
import '../../widgets/concentration_legend.dart';
import '../../widgets/recommendation_panel.dart';
import '../../widgets/demographic_overlay.dart';
import '../../widgets/marker_counter.dart';
import '../../widgets/commercial_modal.dart';
import '../../widgets/integrated_analysis_page.dart';
import '../../widgets/map_legend_widget.dart';
import '../../widgets/postgis_layers_widget.dart';
import '../../widgets/rentas_widget.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _runSearch() async {
    final q = _searchCtrl.text.trim();
    print('🔍 _runSearch() llamado con: "$q"');
    if (q.isEmpty) {
      print('⚠️ Búsqueda vacía, cancelando');
      return;
    }

    print('🚀 Iniciando búsqueda para: "$q"');
    setState(() => _searching = true);
    try {
      await context.read<ExploreController>().geocodeAndMove(q);
      print('✅ Búsqueda completada exitosamente');
    } catch (e) {
      print('❌ Error en búsqueda: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró esa dirección')),
        );
      }
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).padding;
    final exploreController = context.watch<ExploreController>();

    // Cargar marcadores comerciales cuando se selecciona una zona
    if (exploreController.activeCP != null && !exploreController.hasPaintedAZone) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        exploreController.loadCommercialMarkers(context);
      });
    }

    // Mostrar modal comercial cuando se selecciona un marcador
    if (exploreController.selectedCommercialData != null && 
        exploreController.selectedCommercialPosition != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCommercialModal(context, exploreController);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Éxito XY')),
      body: Stack(
        children: [
          const ExploreMap(),
          
          // Custom Info Window
          if (exploreController.customInfoWindowController != null)
            CustomInfoWindow(
              controller: exploreController.customInfoWindowController!,
              height: 200,
              width: 250,
              offset: 100,
            ),
          
          // Search bar
          Positioned(
            left: 12,
            right: 12,
            top: insets.top + 12,
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(Icons.search_rounded, color: Colors.grey),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Buscar dirección o lugar',
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _runSearch(),
                    ),
                  ),
                  IconButton(
                    onPressed: _searching ? null : _runSearch,
                    icon: _searching
                        ? const SizedBox(
                            width: 18, 
                            height: 18, 
                            child: CircularProgressIndicator(strokeWidth: 2)
                          )
                        : const Icon(Icons.arrow_forward_rounded),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
          
          // Activity prompt
          const Positioned(
            right: 12,
            bottom: 18,
            child: ActivityPrompt(),
          ),
          
          // Concentration legend
          if (exploreController.showConcentrationLayer)
            Positioned(
              right: 12,
              top: insets.top + 50,
              child: const ConcentrationLegend(),
            ),
          
          // Demographic overlay
          if (exploreController.demographyAgg != null && exploreController.activeCP != null)
            Positioned(
              top: insets.top + 50,
              left: 12,
              right: 12,
              child: DemographicOverlay(
                demography: exploreController.demographyAgg!,
                postalCode: exploreController.activeCP,
                onClose: () {
                  exploreController.clearDemographicOverlay();
                },
              ),
            ),
          
          // Marker counter
          if (exploreController.countMarkers > 0)
            Positioned(
              top: insets.top + 200,
              right: 12,
              child: MarkerCounter(count: exploreController.countMarkers),
            ),

          // Recommendations button - Reposicionado para no estorbar
          if (exploreController.recommendations.isNotEmpty)
            Positioned(
              right: 8,
              bottom: 140, // Más espacio para no estorbar
              child: FloatingActionButton.extended(
                onPressed: () => _showRecommendations(context, exploreController),
                icon: const Icon(Icons.lightbulb_outline, size: 16),
                label: const Text('Recomendaciones', style: TextStyle(fontSize: 11)),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                elevation: 6,
                extendedPadding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),

          // Análisis Integrado button
          Positioned(
            left: 12,
            bottom: 18,
            child: FloatingActionButton.extended(
              onPressed: () => _showIntegratedAnalysis(context, exploreController),
              icon: const Icon(Icons.analytics),
              label: const Text('Análisis'),
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
            ),
          ),

          // Widget de Rentas (arriba del botón de capas)
          const RentasWidget(),

          // Botón para mostrar capas PostGIS (cuando no hay capas activas)
          if (!exploreController.showPostgisAgebLayer && 
              !exploreController.showPostgisTransporteLayer && 
              !exploreController.showPostgisRutasLayer && 
              !exploreController.showPostgisLineasLayer)
            Positioned(
              left: 12,
              bottom: 80,
              child: FloatingActionButton.extended(
                onPressed: () => _showPostgisLayersMenu(context, exploreController),
                icon: const Icon(Icons.layers),
                label: const Text('Capas GIS'),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
              ),
            ),

          // Botón para mostrar panel de capas (cuando hay capas activas pero panel oculto)
          if ((exploreController.showPostgisAgebLayer || 
              exploreController.showPostgisTransporteLayer || 
              exploreController.showPostgisRutasLayer || 
              exploreController.showPostgisLineasLayer) &&
              !exploreController.showPostgisLayersPanel)
            Positioned(
              right: 12,
              bottom: 80,
              child: FloatingActionButton(
                onPressed: () => exploreController.openPostgisLayersPanel(),
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                child: const Icon(Icons.layers),
              ),
            ),

          // Map Legend - Solo mostrar cuando hay análisis activo
          if (exploreController.showConcentrationLayer)
            Positioned(
              left: 8,
              top: insets.top + 50, // Más arriba para mejor visibilidad
              child: const MapLegendWidget(),
            ),
          
          // PostGIS Layers Control
          if (exploreController.showPostgisLayersPanel)
            Positioned(
              right: 12,
              top: insets.top + 100,
              child: const PostgisLayersWidget(),
            ),
        ],
      ),
    );
  }

  void _showRecommendations(BuildContext context, ExploreController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: RecommendationPanel(
                    recommendations: controller.recommendations,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCommercialModal(BuildContext context, ExploreController controller) {
    if (controller.selectedCommercialData != null && 
        controller.selectedCommercialPosition != null) {
      showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        builder: (BuildContext context) {
          return CommercialModal(
            commercialData: controller.selectedCommercialData!,
            coordinates: controller.selectedCommercialPosition!,
          );
        },
      ).then((_) {
        // Limpiar la selección después de cerrar el modal
        controller.clearCommercialSelection();
      });
    }
  }

  void _showIntegratedAnalysis(BuildContext context, ExploreController controller) {
    final latitude = controller.lastPoint?.latitude ?? 20.6597;
    final longitude = controller.lastPoint?.longitude ?? -103.3496;
    final locationName = 'Ubicación seleccionada';

    // Mostrar análisis integrado directamente sin bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => IntegratedAnalysisPage(
          latitude: latitude,
          longitude: longitude,
          locationName: locationName,
        ),
      ),
    );
  }

  void _showPostgisLayersMenu(BuildContext context, ExploreController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Icon(Icons.layers, color: Colors.teal[700], size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Capas PostGIS',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Botón Colonias
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.location_city, color: Colors.blue[700]),
              ),
              title: const Text('Colonias', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Datos demográficos por colonia'),
              trailing: Switch(
                value: controller.showPostgisAgebLayer,
                onChanged: (value) {
                  Navigator.pop(context);
                  controller.loadPostgisLayers(
                    showAgeb: value,
                    showTransporte: controller.showPostgisTransporteLayer,
                    showRutas: controller.showPostgisRutasLayer,
                    showLineas: controller.showPostgisLineasLayer,
                  );
                },
              ),
            ),
            
            const Divider(),
            
            // Botón Transporte (Estaciones)
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.directions_bus, color: Colors.purple[700]),
              ),
              title: const Text('Estaciones', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Estaciones de transporte masivo'),
              trailing: Switch(
                value: controller.showPostgisTransporteLayer,
                onChanged: (value) {
                  Navigator.pop(context);
                  controller.loadPostgisLayers(
                    showAgeb: controller.showPostgisAgebLayer,
                    showTransporte: value,
                    showRutas: controller.showPostgisRutasLayer,
                    showLineas: controller.showPostgisLineasLayer,
                  );
                },
              ),
            ),
            
            const Divider(),
            
            // Botón Rutas
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.route, color: Colors.orange[700]),
              ),
              title: const Text('Rutas', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Red de transporte y rutas'),
              trailing: Switch(
                value: controller.showPostgisRutasLayer,
                onChanged: (value) {
                  Navigator.pop(context);
                  controller.loadPostgisLayers(
                    showAgeb: controller.showPostgisAgebLayer,
                    showTransporte: controller.showPostgisTransporteLayer,
                    showRutas: value,
                    showLineas: controller.showPostgisLineasLayer,
                  );
                },
              ),
            ),
            
            const Divider(),
            
            // Botón Líneas
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.timeline, color: Colors.red[700]),
              ),
              title: const Text('Líneas', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: const Text('Transporte masivo y alimentador'),
              trailing: Switch(
                value: controller.showPostgisLineasLayer,
                onChanged: (value) {
                  Navigator.pop(context);
                  controller.loadPostgisLayers(
                    showAgeb: controller.showPostgisAgebLayer,
                    showTransporte: controller.showPostgisTransporteLayer,
                    showRutas: controller.showPostgisRutasLayer,
                    showLineas: value,
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
