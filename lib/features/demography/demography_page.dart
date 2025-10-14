import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../explore/explore_controller.dart';

/// Pantalla de Demografía.
/// Puede recibir `agg` y `cp` explícitos, o (si vienen nulos) tomarlos del ExploreController.
class DemographyPage extends StatelessWidget {
  final Map<String, int>? agg; // {'t','m','f'}
  final String? cp;

  const DemographyPage({super.key, this.agg, this.cp});

  @override
  Widget build(BuildContext context) {
    // Si no nos pasaron datos, leemos del ExploreController
    final explore = context.watch<ExploreController>();
    final data = agg ?? explore.demographyAgg;
    final postal = cp ?? explore.activeCP;

    return Scaffold(
      appBar: AppBar(title: const Text('Demografía')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Builder(
          builder: (_) {
            if (data == null || postal == null) {
              return _EmptyHint(
                text:
                    'Selecciona una zona en "Explorar" (tap en el mapa o busca una dirección).\n\n'
                    'Se dibujarán los AGEBS y aquí verás los agregados demográficos del CP.',
              );
            }

            final total = data['t'] ?? 0;
            final hombres = data['m'] ?? 0;
            final mujeres = data['f'] ?? 0;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CP $postal',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _metric('Total', total),
                    _metric('Hombres', hombres),
                    _metric('Mujeres', mujeres),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 12),
                Text(
                  'Cómo se llena esta pantalla',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cuando en "Explorar" seleccionas un punto o buscas una dirección, '
                  'hacemos reverse geocoding → CP, pedimos a MySQL las AGEBS de ese CP, '
                  'pintamos los polígonos y agregamos t/m/f. Esos agregados se muestran aquí.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _metric(String label, int value) {
    return Column(
      children: [
        Text(
          '$value',
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final String text;
  const _EmptyHint({required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style:
            Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
      ),
    );
  }
}
