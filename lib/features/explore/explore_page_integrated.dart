import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import 'explore_controller.dart';
import '../../widgets/integrated_analysis_widget.dart';

class ExplorePageIntegrated extends StatefulWidget {
  const ExplorePageIntegrated({super.key});

  @override
  State<ExplorePageIntegrated> createState() => _ExplorePageIntegratedState();
}

class _ExplorePageIntegratedState extends State<ExplorePageIntegrated> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  double _currentLatitude = 20.6597; // Guadalajara por defecto
  double _currentLongitude = -103.3496;
  String _currentLocationName = 'Guadalajara, Jalisco';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchLocation() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;

    setState(() => _isSearching = true);
    
    try {
      // Usar el controlador existente para geocodificar
      await context.read<ExploreController>().geocodeAndMove(query);
      
      // Actualizar las coordenadas actuales
      final controller = context.read<ExploreController>();
      if (controller.lastPoint != null) {
        setState(() {
          _currentLatitude = controller.lastPoint!.latitude;
          _currentLongitude = controller.lastPoint!.longitude;
          _currentLocationName = query;
        });
      }
    } catch (e) {
      print('Error en búsqueda: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró esa ubicación')),
      );
    } finally {
      setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'exitoxy',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundColor: colorScheme.primary,
              child: Text(
                'K',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(
                  Icons.search,
                  color: colorScheme.onSurface.withOpacity(0.6),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar ubicación...',
                      hintStyle: GoogleFonts.poppins(
                        color: colorScheme.onSurface.withOpacity(0.5),
                      ),
                      border: InputBorder.none,
                    ),
                    style: GoogleFonts.poppins(),
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _searchLocation(),
                  ),
                ),
                if (_isSearching)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: _searchLocation,
                    icon: Icon(
                      Icons.arrow_forward,
                      color: colorScheme.primary,
                    ),
                  ),
              ],
            ),
          ),
          
          // Widget integrado
          Expanded(
            child: IntegratedAnalysisWidget(
              latitude: _currentLatitude,
              longitude: _currentLongitude,
              locationName: _currentLocationName,
            ),
          ),
        ],
      ),
    );
  }
}
