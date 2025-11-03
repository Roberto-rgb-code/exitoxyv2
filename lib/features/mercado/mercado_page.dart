import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../explore/explore_controller.dart';
import '../../widgets/mercado_elasticidad_widget.dart';

/// Página de Análisis de Elasticidad de Mercado
class MercadoPage extends StatelessWidget {
  const MercadoPage({super.key});

  @override
  Widget build(BuildContext context) {
    final explore = context.watch<ExploreController>();
    
    // Obtener ubicación del ExploreController o usar valores por defecto
    final lat = explore.lastPoint?.latitude ?? 20.6599162; // Guadalajara
    final lon = explore.lastPoint?.longitude ?? -103.3450723;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Elasticidad de Mercado'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: MercadoElasticidadWidget(
        latitude: lat,
        longitude: lon,
      ),
    );
  }
}

