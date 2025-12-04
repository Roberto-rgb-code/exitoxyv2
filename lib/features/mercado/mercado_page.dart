import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../explore/explore_controller.dart';
import '../../widgets/mercado_elasticidad_widget.dart';
import '../../widgets/glossary_term_widget.dart';

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
        title: Row(
          children: const [
            Icon(Icons.trending_up_rounded),
            SizedBox(width: 8),
            Text('Elasticidad de Mercado'),
          ],
        ),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GlossaryPage()),
            ),
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'Glosario de términos',
          ),
        ],
      ),
      body: MercadoElasticidadWidget(
        latitude: lat,
        longitude: lon,
      ),
    );
  }
}

