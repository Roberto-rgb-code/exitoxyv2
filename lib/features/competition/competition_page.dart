import 'dart:math';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

import '../../services/denue_repository.dart';
import '../../services/concentration_service.dart';
import '../../services/cache_service.dart';
import '../../services/recommendation_service.dart';
import '../../models/concentration_result.dart';
import '../../models/recommendation.dart';
import '../explore/widgets/concentration_panel.dart';
import '../../widgets/recommendation_panel.dart';

class CompetitionPage extends StatefulWidget {
  const CompetitionPage({super.key});

  @override
  State<CompetitionPage> createState() => _CompetitionPageState();
}

class _CompetitionPageState extends State<CompetitionPage> {
  final _actCtrl = TextEditingController();
  final _cpCtrl = TextEditingController();
  bool _loading = false;
  ConcentrationResult? _result;
  List<Recommendation> _recommendations = [];

  @override
  void dispose() {
    _actCtrl.dispose();
    _cpCtrl.dispose();
    super.dispose();
  }

  Future<void> _compute() async {
    final act = _actCtrl.text.trim();
    final cp = _cpCtrl.text.trim();

    if (act.isEmpty || cp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe actividad y código postal')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
      _recommendations.clear();
    });

    try {
      // 1) Geocodifica CP -> centro
      final locations = await locationFromAddress('$cp, México');
      final lat = locations.first.latitude;
      final lon = locations.first.longitude;

      // 2) Verificar cache
      var cached = CacheService.get(act, cp);
      if (cached == null) {
        // 3) Obtener datos DENUE
        final entries = await DenueRepository.fetchEntries(
          activity: act,
          lat: lat,
          lon: lon,
          postalCode: cp,
        );

        // 4) Calcular concentración usando el servicio
        cached = ConcentrationService.compute(
          entries: entries,
          activity: act,
          postalCode: cp,
        );

        // 5) Guardar en cache
        CacheService.put(act, cp, cached);
      }

      // 6) Generar recomendaciones (simulamos demografía básica)
      final demography = {'t': 5000, 'm': 2500, 'f': 2500}; // Datos simulados
      final recommendationService = RecommendationService();
      _recommendations = await recommendationService.generateRecommendations(
        latitude: 20.6597, // Coordenadas de Guadalajara
        longitude: -103.3496,
        locationName: 'Guadalajara, Jalisco',
      );

      setState(() => _result = cached);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo calcular: revisa actividad/CP')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Competencia')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Índice de concentración (DENUE: HHI / CR4)', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: _actCtrl,
            decoration: const InputDecoration(
              labelText: 'Actividad económica (ej. abarrotes)',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _cpCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Código postal',
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _loading ? null : _compute,
            icon: const Icon(Icons.bar_chart_rounded),
            label: _loading ? const Text('Calculando...') : const Text('Calcular'),
          ),
          const SizedBox(height: 16),
          if (_result != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: ConcentrationPanel(result: _result!),
              ),
            ),
            const SizedBox(height: 16),
            if (_recommendations.isNotEmpty) ...[
              Text('Recomendaciones', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: RecommendationPanel(recommendations: _recommendations),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }
}
