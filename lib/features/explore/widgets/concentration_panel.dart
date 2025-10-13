import 'package:flutter/material.dart';
import '../../../models/concentration_result.dart';

class ConcentrationPanel extends StatelessWidget {
  final ConcentrationResult result;
  const ConcentrationPanel({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final txt = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
              decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text('Concentración del mercado', style: txt.titleMedium),
            const SizedBox(height: 6),
            Text('${result.activity}${result.postalCode != null ? ' · CP ${result.postalCode}' : ''}', style: txt.bodyMedium),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metric('Empresas', '${result.nFirms}'),
                _metric('HHI', result.hhi.toStringAsFixed(0)),
                _metric('CR4', '${(result.cr4 * 100).toStringAsFixed(1)}%'),
                _metric('Nivel', _levelLabel(result.level)),
              ],
            ),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: Text('Top empresas', style: txt.titleSmall)),
            const SizedBox(height: 8),
            Column(
              children: result.topFirms.map((e) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(e.key, overflow: TextOverflow.ellipsis)),
                  Text('${(e.value * 100).toStringAsFixed(1)}%'),
                ],
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) => Column(
    children: [
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      Text(label, style: const TextStyle(color: Colors.grey)),
    ],
  );

  String _levelLabel(ConcentrationLevel level) {
    switch (level) {
      case ConcentrationLevel.low:      return 'Baja';
      case ConcentrationLevel.moderate: return 'Moderada';
      case ConcentrationLevel.high:     return 'Alta';
      case ConcentrationLevel.veryHigh: return 'Muy alta';
    }
  }
}
