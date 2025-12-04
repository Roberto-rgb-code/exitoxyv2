import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../explore_controller.dart";
import "../../../widgets/glossary_tooltip.dart";

class ActivityPrompt extends StatefulWidget {
  const ActivityPrompt({super.key});

  @override
  State<ActivityPrompt> createState() => _ActivityPromptState();
}

class _ActivityPromptState extends State<ActivityPrompt> {
  final _activityController = TextEditingController();
  bool _isAnalyzing = false;

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  /// Análisis completo con un solo click
  /// Busca: DENUE (negocios), Delitos, Propiedades, Concentración
  Future<void> _analyzeAll() async {
    final activity = _activityController.text.trim();
    if (activity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Escribe una actividad económica (ej: abarrotes, farmacia, restaurante)'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final controller = context.read<ExploreController>();
    
    if (controller.lastPoint == null || controller.activeCP == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('📍 Primero selecciona una zona (tap en el mapa o busca una dirección)'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }
    
    setState(() => _isAnalyzing = true);
    
    try {
      print('🚀 ANÁLISIS COMPLETO para: "$activity"');
      print('📍 Ubicación: ${controller.lastPoint}');
      print('📍 CP: ${controller.activeCP}');
      
      // Mostrar snackbar de inicio
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('Buscando "$activity" - negocios, delitos, propiedades...'),
                ),
              ],
            ),
            backgroundColor: Colors.blue,
            duration: const Duration(seconds: 10),
          ),
        );
      }
      
      // Ejecutar análisis completo
      await controller.analyzeConcentration(activity);
      
      // Verificar resultados
      final denueCount = controller.allMarkers().where((m) => m.markerId.value.startsWith('denue_')).length;
      final delitosCount = controller.allMarkers().where((m) => m.markerId.value.startsWith('delito_')).length;
      final placesCount = controller.allMarkers().where((m) => m.markerId.value.startsWith('places_')).length;
      
      print('📊 Resultados:');
      print('   - DENUE: $denueCount negocios');
      print('   - Delitos: $delitosCount reportes');
      print('   - Propiedades: $placesCount');
      
      // Mostrar resultado exitoso
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Análisis completado: "$activity"', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('🏪 $denueCount negocios DENUE', style: const TextStyle(fontSize: 12)),
                Text('🚨 $delitosCount reportes de delitos', style: const TextStyle(fontSize: 12)),
                if (placesCount > 0)
                  Text('🏠 $placesCount propiedades', style: const TextStyle(fontSize: 12))
                else
                  const Text('🏠 Propiedades: API no configurada', style: TextStyle(fontSize: 12, color: Colors.white70)),
                const Text('📊 HHI/CR4 calculados', style: TextStyle(fontSize: 12)),
              ],
            ),
            backgroundColor: Colors.green[700],
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      print('❌ ERROR en análisis: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAnalyzing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreController>(
      builder: (context, controller, child) {
        if (controller.lastPoint == null) {
          return const SizedBox.shrink();
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón para ocultar capas de concentración
            if (controller.showConcentrationLayer)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: FloatingActionButton.small(
                  onPressed: controller.hideConcentrationLayer,
                  backgroundColor: Colors.red,
                  child: const Icon(Icons.visibility_off, size: 20),
                ),
              ),
            
            // Input y botón de análisis
            Container(
              width: 220,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
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
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(Icons.analytics, color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Analizar zona',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      GlossaryHelpIcon(
                        termKey: 'denue',
                        color: Colors.grey[500],
                        size: 16,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Campo de texto
                  TextField(
                    controller: _activityController,
                    enabled: !_isAnalyzing,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _analyzeAll(),
                    decoration: InputDecoration(
                      hintText: 'ej: abarrotes, farmacia...',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[400],
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.blue[400]!, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      isDense: true,
                    ),
                    style: const TextStyle(fontSize: 14),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Botón de análisis - UN SOLO CLICK
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzeAll,
                      icon: _isAnalyzing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.search, size: 18),
                      label: Text(
                        _isAnalyzing ? 'Buscando...' : 'Buscar Todo',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                    ),
                  ),
                  
                  // Info de lo que se busca
                  if (!_isAnalyzing) ...[
                    const SizedBox(height: 8),
                    Text(
                      '🏪 Negocios • 🚨 Delitos • 🏠 Propiedades',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[500],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
