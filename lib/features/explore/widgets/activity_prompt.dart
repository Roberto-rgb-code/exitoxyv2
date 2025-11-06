import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../explore_controller.dart";

class ActivityPrompt extends StatefulWidget {
  const ActivityPrompt({super.key});

  @override
  State<ActivityPrompt> createState() => _ActivityPromptState();
}

class _ActivityPromptState extends State<ActivityPrompt> {
  final _activityController = TextEditingController();
  bool _isValidating = false;
  bool _isValidActivity = false;

  @override
  void dispose() {
    _activityController.dispose();
    super.dispose();
  }

  Future<void> _validateActivity() async {
    final activity = _activityController.text.trim();
    if (activity.isEmpty) return;

    setState(() => _isValidating = true);
    
    try {
      // Validar la actividad económica
      // Por ahora, asumimos que cualquier texto no vacío es válido
      // Podrías agregar validación con DENUE API aquí
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        setState(() => _isValidActivity = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Actividad válida: $activity'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isValidActivity = false);
      }
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
      }
    }
  }

  Future<void> _analyzeConcentration() async {
    final activity = _activityController.text.trim();
    if (activity.isEmpty) return;

    final controller = context.read<ExploreController>();
    
    if (controller.lastPoint == null || controller.activeCP == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor selecciona una zona primero (tap en el mapa o busca una dirección)'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }
    
    try {
      setState(() => _isValidating = true);
      
      // 1. Analizar la concentración (esto también genera recomendaciones)
      await controller.analyzeConcentration(activity);
      
      // 2. Mostrar los marcadores DENUE en el mapa
      await controller.showDenueMarkers(activity);
      
      // 3. Cargar y mostrar marcadores de delitos
      await controller.showDelitosMarkers();
      
      setState(() => _isValidActivity = true);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('✅ Análisis completado: $activity'),
                const SizedBox(height: 4),
                Text(
                  '📍 Marcadores mostrados en el mapa',
                  style: TextStyle(fontSize: 12),
                ),
                Text(
                  '🎯 Ver recomendaciones abajo',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      setState(() => _isValidActivity = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error analizando "$activity": ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isValidating = false);
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
            // Botón para análisis de concentración
            if (controller.showConcentrationLayer)
              FloatingActionButton(
                onPressed: controller.hideConcentrationLayer,
                backgroundColor: Colors.red,
                child: const Icon(Icons.visibility_off),
              ),
            
            const SizedBox(height: 8),
            
            // Input de actividad económica
            Container(
              width: 200,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _activityController,
                    decoration: InputDecoration(
                      hintText: 'Actividad económica',
                      border: InputBorder.none,
                      suffixIcon: _isValidating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : IconButton(
                              icon: Icon(
                                _isValidActivity ? Icons.check_circle : Icons.search,
                                color: _isValidActivity ? Colors.green : Colors.grey,
                              ),
                              onPressed: _validateActivity,
                            ),
                    ),
                    onChanged: (value) {
                      setState(() => _isValidActivity = false);
                    },
                    onSubmitted: (_) => _validateActivity(),
                  ),
                  
                  if (_isValidActivity) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _analyzeConcentration,
                        icon: const Icon(Icons.analytics, size: 16),
                        label: const Text('Analizar'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                      ),
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
