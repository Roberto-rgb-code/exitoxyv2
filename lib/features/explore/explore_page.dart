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
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.search_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      decoration: const InputDecoration(
                        hintText: 'Buscar dirección o lugar',
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _runSearch(),
                    ),
                  ),
                  IconButton(
                    onPressed: _searching ? null : _runSearch,
                    icon: _searching
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.arrow_forward_rounded),
                  ),
                  // Botón de prueba temporal
                  IconButton(
                    onPressed: () {
                      _searchCtrl.text = 'centro';
                      _runSearch();
                    },
                    icon: const Icon(Icons.bug_report, color: Colors.red),
                  ),
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
              top: insets.top + 80,
              child: const ConcentrationLegend(),
            ),
          
          // Demographic overlay
          if (exploreController.demographyAgg != null && exploreController.activeCP != null)
            Positioned(
              top: insets.top + 80,
              left: 12,
              right: 12,
              child: DemographicOverlay(
                demography: exploreController.demographyAgg!,
                postalCode: exploreController.activeCP,
              ),
            ),
          
          // Marker counter
          if (exploreController.countMarkers > 0)
            Positioned(
              top: insets.top + 200,
              right: 12,
              child: MarkerCounter(count: exploreController.countMarkers),
            ),

          // Recommendations button
          if (exploreController.recommendations.isNotEmpty)
            Positioned(
              left: 12,
              bottom: 18,
              child: FloatingActionButton.extended(
                onPressed: () => _showRecommendations(context, exploreController),
                icon: const Icon(Icons.lightbulb_outline),
                label: const Text('Recomendaciones'),
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
              ),
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
}
