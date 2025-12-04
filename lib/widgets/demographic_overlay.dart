import 'package:flutter/material.dart';
import 'glossary_tooltip.dart';

class DemographicOverlay extends StatelessWidget {
  final Map<String, int> demography;
  final String? postalCode;
  final VoidCallback? onClose;

  const DemographicOverlay({
    Key? key,
    required this.demography,
    this.postalCode,
    this.onClose,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final total = demography['t'] ?? 0;
    final hombres = demography['m'] ?? 0;
    final mujeres = demography['f'] ?? 0;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header con título y tooltip
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Datos Demográficos',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 6),
                  GlossaryHelpIcon(
                    termKey: 'pobtot',
                    color: Colors.white70,
                    size: 16,
                  ),
                ],
              ),
              if (postalCode != null) ...[
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'CP $postalCode',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GlossaryHelpIcon(
                      termKey: 'ageb',
                      color: Colors.white60,
                      size: 14,
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDemographicItem(
                    context: context,
                    icon: Icons.woman,
                    label: 'Femenino',
                    value: mujeres,
                  ),
                  _buildDemographicItem(
                    context: context,
                    icon: Icons.man,
                    label: 'Masculino',
                    value: hombres,
                  ),
                  _buildDemographicItem(
                    context: context,
                    icon: Icons.people,
                    label: 'Total',
                    value: total,
                    glossaryKey: 'pobtot',
                  ),
                ],
              ),
            ],
          ),
          if (onClose != null)
            Positioned(
              top: 0,
              right: 0,
              child: Material(
                color: Colors.black.withOpacity(0.5),
                shape: const CircleBorder(),
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDemographicItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required int value,
    String? glossaryKey,
  }) {
    return GestureDetector(
      onTap: glossaryKey != null ? () => showGlossaryModal(context, glossaryKey) : null,
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 24,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$label: ${_formatNumber(value)}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
              if (glossaryKey != null) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.help_outline_rounded,
                  size: 12,
                  color: Colors.white70,
                ),
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
