import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show CameraUpdate;

import '../../core/debounce.dart';
import 'explore_controller.dart';
import 'map/explore_map.dart';

class ExplorePage extends StatefulWidget {
  const ExplorePage({super.key});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final _debounce = Debouncer(milliseconds: 450);
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _debounce.dispose();
    super.dispose();
  }

  Future<void> _runSearch(BuildContext context) async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    await context.read<ExploreController>().geocodeAndMove(q);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ExploreController>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          const ExploreMap(),

          // Filtros tipo chip
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 12,
            right: 12,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Row(
                children: const [
                  _FilterChip(icon: Icons.attach_money_rounded, label: 'Precio'),
                  SizedBox(width: 8),
                  _FilterChip(icon: Icons.square_foot_rounded, label: 'm²'),
                  SizedBox(width: 8),
                  _FilterChip(icon: Icons.bed_rounded, label: 'Cuartos'),
                  SizedBox(width: 8),
                  _FilterChip(icon: Icons.bathtub_rounded, label: 'Baños'),
                  SizedBox(width: 8),
                  _FilterChip(icon: Icons.local_parking_rounded, label: 'Cajones'),
                ],
              ),
            ),
          ),

          // Buscador superior
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 12,
            right: 12,
            child: Material(
              elevation: 3,
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.surface,
              child: TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _runSearch(context),
                onChanged: (_) => _debounce.run(() => _runSearch(context)),
                decoration: InputDecoration(
                  hintText: 'Ingresa una dirección o zona',
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchCtrl.clear();
                      FocusScope.of(context).unfocus();
                    },
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Theme.of(context).dividerColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary, width: 1.6),
                  ),
                ),
              ),
            ),
          ),

          // Botón de recenter
          Positioned(
            right: 16,
            bottom: 24 + MediaQuery.of(context).padding.bottom,
            child: FloatingActionButton(
              heroTag: 'recenter',
              onPressed: () async {
                final p = c.lastPoint;
                if (p == null) return;
                await c.mapCtrl?.animateCamera(
                  CameraUpdate.newLatLngZoom(p, 15),
                );
              },
              child: const Icon(Icons.my_location_rounded),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: cs.primary),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: cs.onSurface)),
        ],
      ),
    );
  }
}
