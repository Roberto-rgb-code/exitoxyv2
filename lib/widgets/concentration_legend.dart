import 'package:flutter/material.dart';
import 'glossary_tooltip.dart';

class ConcentrationLegend extends StatelessWidget {
  const ConcentrationLegend({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Nivel de Concentración',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 4),
              GlossaryHelpIcon(
                termKey: 'hhi',
                color: Colors.grey[700],
                size: 14,
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildLegendItem(context, 'Baja', 0xFF2e7d32, 'Competencia Perfecta'),
          _buildLegendItem(context, 'Moderada', 0xFFf9a825, 'Competencia Monopolística'),
          _buildLegendItem(context, 'Alta', 0xFFef6c00, 'Oligopolio'),
          _buildLegendItem(context, 'Muy Alta', 0xFFc62828, 'Monopolio'),
        ],
      ),
    );
  }

  Widget _buildLegendItem(BuildContext context, String label, int color, String termKey) {
    // Mapear label a key del glosario
    String glossaryKey;
    switch (label) {
      case 'Baja':
        glossaryKey = 'competencia_perfecta';
        break;
      case 'Moderada':
        glossaryKey = 'competencia_monopolistica';
        break;
      case 'Alta':
        glossaryKey = 'oligopolio';
        break;
      case 'Muy Alta':
        glossaryKey = 'monopolio';
        break;
      default:
        glossaryKey = 'estructura_mercado';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: InkWell(
        onTap: () => showGlossaryModal(context, glossaryKey),
        borderRadius: BorderRadius.circular(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: Color(color),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 11),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.help_outline_rounded,
              size: 12,
              color: Colors.grey[500],
            ),
          ],
        ),
      ),
    );
  }
}
