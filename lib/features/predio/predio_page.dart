import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../services/visorurbano_service.dart';
import '../../widgets/panel_card.dart';

class PredioPage extends StatefulWidget {
  const PredioPage({super.key});

  @override
  State<PredioPage> createState() => _PredioPageState();
}

class _PredioPageState extends State<PredioPage> {
  bool loading = false;
  Map<String, dynamic>? predio;

  Future<void> _consult(LatLng p) async {
    setState(() { loading = true; predio = null; });
    try {
      final data = await VisorUrbanoService.predioPorLatLon(p.latitude, p.longitude);
      if (data.isNotEmpty) predio = Map<String, dynamic>.from(data[0]);
      setState(() {});
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error VisorUrbano: $e')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.select<AppState, LatLng?>((s) => s.lastPoint);
    return Scaffold(
      appBar: AppBar(title: const Text('Predio')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          PanelCard(
            title: 'Ubicación',
            children: [
              Text(p == null
                  ? 'Selecciona un punto en Explorar (tap largo) o buscador.'
                  : 'Punto seleccionado: ${p.latitude.toStringAsFixed(6)}, ${p.longitude.toStringAsFixed(6)}'),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: (p == null || loading) ? null : () => _consult(p),
                icon: const Icon(Icons.gavel_rounded),
                label: Text(loading ? 'Consultando...' : 'Consultar predio'),
              ),
            ],
          ),
          if (predio != null)
            PanelCard(
              title: 'Datos del predio',
              children: [
                _row('Clave', '${predio!['clave']}'),
                _row('Tipo', '${predio!['tipo']}'),
                _row('Ubicación', '${predio!['ubicacion']}'),
                _row('Colonia', '${predio!['colonia']}'),
                _row('Sup. legal', '${predio!['superficieLegal']} m²'),
                _row('Sup. carto', '${predio!['superficieCarto']} m²'),
                _row('Construcción', '${predio!['superficieConstruccion']} m²'),
                _row('Frente', '${predio!['frente']} m'),
                _row('Cos', '${predio!['cos']}'),
                _row('Cus', '${predio!['cus']}'),
                const SizedBox(height: 8),
                const Text('Usos permitidos:'),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 6, runSpacing: 6,
                  children: List<String>.from(predio!['zonificacion_default']['usos_permitidos'] ?? [])
                      .map((e) => Chip(label: Text(e))).toList(),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        SizedBox(width: 140, child: Text('$k:', style: const TextStyle(fontWeight: FontWeight.bold))),
        Expanded(child: Text(v)),
      ],
    ),
  );
}
