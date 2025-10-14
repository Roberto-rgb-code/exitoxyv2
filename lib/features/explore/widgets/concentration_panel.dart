import 'package:flutter/material.dart';
import 'package:kitit_v2/models/concentration_result.dart';

class ConcentrationPanel extends StatelessWidget {
  final ConcentrationResult result;
  const ConcentrationPanel({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final txt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Índice de concentración', style: txt.titleMedium),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _metric('HHI', result.hhi.toStringAsFixed(0)),
            _metric('CR4', '${result.cr4.toStringAsFixed(1)}%'),
            _badgeLevel(_levelLabel(result.level), Color(result.color)),
          ],
        ),

        const SizedBox(height: 16),
        Text('Top cadenas', style: txt.titleSmall),
        const SizedBox(height: 6),
        if (result.topChains.isEmpty)
          const Text('Sin datos de cadenas')
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: result.topChains.take(10).map((e) => Row(
              children: [
                const Icon(Icons.storefront, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(e)),
              ],
            )).toList(),
          ),
      ],
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Widget _badgeLevel(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
    );
  }

  String _levelLabel(String level) {
    switch (level) {
      case 'low': return 'Baja';
      case 'moderate': return 'Moderada';
      case 'high': return 'Alta';
      case 'veryHigh': return 'Muy alta';
      default: return '—';
    }
  }
}
