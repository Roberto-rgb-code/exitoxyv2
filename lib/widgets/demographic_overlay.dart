import 'package:flutter/material.dart';

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
              if (postalCode != null) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    'CP $postalCode',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDemographicItem(
                    icon: Icons.woman,
                    label: 'Femenino',
                    value: mujeres,
                  ),
                  _buildDemographicItem(
                    icon: Icons.man,
                    label: 'Masculino',
                    value: hombres,
                  ),
                  _buildDemographicItem(
                    icon: Icons.people,
                    label: 'Total',
                    value: total,
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
    required IconData icon,
    required String label,
    required int value,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          color: Colors.white,
          size: 24,
        ),
        const SizedBox(height: 4),
        Text(
          '$label: $value',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
