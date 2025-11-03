import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../explore/explore_controller.dart';
import '../../widgets/analisis_mercado_widget.dart';

/// Página de Análisis de Estructura de Mercado
class AnalisisPage extends StatelessWidget {
  const AnalisisPage({super.key});

  @override
  Widget build(BuildContext context) {
    final explore = context.watch<ExploreController>();
    
    // Obtener ubicación del ExploreController o usar valores por defecto
    final lat = explore.lastPoint?.latitude ?? 20.6599162; // Guadalajara
    final lon = explore.lastPoint?.longitude ?? -103.3450723;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis de Mercado'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: AnalisisMercadoWidget(
        latitude: lat,
        longitude: lon,
      ),
    );
  }
}

