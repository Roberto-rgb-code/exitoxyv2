import 'package:flutter/material.dart';

class DemographicOverlay extends StatelessWidget {
  final Map<String, int> demography;
  final String? postalCode;

  const DemographicOverlay({
    Key? key,
    required this.demography,
    this.postalCode,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (postalCode != null) ...[
            Text(
              'CP $postalCode',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
