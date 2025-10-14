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
      // Aquí podrías validar la actividad con DENUE
      // Por ahora, asumimos que es válida si no está vacía
      setState(() => _isValidActivity = true);
    } catch (e) {
      setState(() => _isValidActivity = false);
    } finally {
      setState(() => _isValidating = false);
    }
  }

  Future<void> _analyzeConcentration() async {
    final activity = _activityController.text.trim();
    if (activity.isEmpty || !_isValidActivity) return;

    final controller = context.read<ExploreController>();
    
    try {
      await controller.analyzeConcentration(activity);
      await controller.showDenueMarkers(activity);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Análisis de concentración completado'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
