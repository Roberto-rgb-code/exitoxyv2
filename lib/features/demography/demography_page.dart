import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../explore/explore_controller.dart';
import '../../widgets/glossary_tooltip.dart';

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
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.people_alt_rounded),
            const SizedBox(width: 8),
            const Text('Demografía'),
            const SizedBox(width: 8),
            GlossaryHelpIcon(
              termKey: 'pobtot',
              color: Theme.of(context).colorScheme.onSurface,
              size: 18,
            ),
          ],
        ),
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
                // Código postal con tooltip de AGEB
                Row(
                  children: [
                    Text('CP $postal', style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => showGlossaryModal(context, 'ageb'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'AGEB',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[700],
                              ),
                            ),
                            const SizedBox(width: 4),
                            GlossaryHelpIcon(
                              termKey: 'ageb',
                              color: Colors.orange[700],
                              size: 12,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Métricas demográficas con tooltips
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.people, color: Colors.blue[700]),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => showGlossaryModal(context, 'pobtot'),
                              child: Row(
                                children: [
                                  Text(
                                    'Población Total',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  GlossaryHelpIcon(
                                    termKey: 'pobtot',
                                    color: Colors.blue[700],
                                    size: 14,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _metricWithTooltip(context, 'Total', total, 'pobtot', Colors.blue),
                            _metricWithTooltip(context, 'Hombres', hombres, null, Colors.indigo),
                            _metricWithTooltip(context, 'Mujeres', mujeres, null, Colors.pink),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tarjeta de PEA
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => showGlossaryModal(context, 'pea'),
                          child: Row(
                            children: [
                              Icon(Icons.work, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Población Económicamente Activa',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                ),
                              ),
                              const SizedBox(width: 4),
                              GlossaryHelpIcon(
                                termKey: 'pea',
                                color: Colors.green[700],
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Datos disponibles al seleccionar una colonia en capas PostGIS',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Tarjeta de Escolaridad
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () => showGlossaryModal(context, 'graproes'),
                          child: Row(
                            children: [
                              Icon(Icons.school, color: Colors.purple[700]),
                              const SizedBox(width: 8),
                              Text(
                                'Grado de Escolaridad',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple[700],
                                ),
                              ),
                              const SizedBox(width: 4),
                              GlossaryHelpIcon(
                                termKey: 'graproes',
                                color: Colors.purple[700],
                                size: 14,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Datos disponibles al seleccionar una colonia en capas PostGIS',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
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

  Widget _metricWithTooltip(BuildContext context, String label, int value, String? glossaryKey, Color color) {
    return GestureDetector(
      onTap: glossaryKey != null ? () => showGlossaryModal(context, glossaryKey) : null,
      child: Column(
        children: [
          Text(
            _formatNumber(value),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(color: Colors.grey)),
              if (glossaryKey != null) ...[
                const SizedBox(width: 4),
                Icon(Icons.help_outline_rounded, size: 12, color: Colors.grey[400]),
              ],
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
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
