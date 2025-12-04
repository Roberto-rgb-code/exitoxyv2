import 'package:flutter/material.dart';
import 'package:kitit_v2/models/concentration_result.dart';
import '../../../widgets/glossary_tooltip.dart';

class ConcentrationPanel extends StatelessWidget {
  final ConcentrationResult result;
  const ConcentrationPanel({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final txt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Título con tooltip
        Row(
          children: [
            Text('Índice de concentración', style: txt.titleMedium),
            const SizedBox(width: 8),
            GlossaryHelpIcon(
              termKey: 'hhi',
              color: Colors.grey[600],
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 12),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _metricWithTooltip(context, 'HHI', result.hhi.toStringAsFixed(0), 'hhi', Colors.orange),
            _metricWithTooltip(context, 'CR4', '${result.cr4.toStringAsFixed(1)}%', 'cr4', Colors.purple),
            _badgeLevelWithTooltip(context, _levelLabel(result.level), Color(result.color), result.level),
          ],
        ),

        const SizedBox(height: 16),
        
        // Top cadenas con tooltip
        Row(
          children: [
            Text('Top cadenas', style: txt.titleSmall),
            const SizedBox(width: 4),
            GlossaryHelpIcon(
              termKey: 'cuota_mercado',
              color: Colors.grey[500],
              size: 14,
            ),
          ],
        ),
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

  Widget _metricWithTooltip(BuildContext context, String label, String value, String glossaryKey, Color color) {
    return GestureDetector(
      onTap: () => showGlossaryModal(context, glossaryKey),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 4),
              GlossaryHelpIcon(
                termKey: glossaryKey,
                color: color,
                size: 12,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _badgeLevelWithTooltip(BuildContext context, String label, Color color, String level) {
    // Mapear nivel a término del glosario
    String glossaryKey;
    switch (level) {
      case 'low':
        glossaryKey = 'competencia_perfecta';
        break;
      case 'moderate':
        glossaryKey = 'competencia_monopolistica';
        break;
      case 'high':
        glossaryKey = 'oligopolio';
        break;
      case 'veryHigh':
        glossaryKey = 'monopolio';
        break;
      default:
        glossaryKey = 'estructura_mercado';
    }

    return GestureDetector(
      onTap: () => showGlossaryModal(context, glossaryKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.help_outline_rounded,
              size: 14,
              color: color,
            ),
          ],
        ),
      ),
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
