import 'package:flutter/material.dart';

class PolygonInfoWindow extends StatelessWidget {
  final Map<String, dynamic> data;
  final String agebId;

  const PolygonInfoWindow({
    Key? key,
    required this.data,
    required this.agebId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF00BCD4), // Borde turquesa
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.layers, color: const Color(0xFF00BCD4), size: 24),
              const SizedBox(width: 8),
              Text(
                'AGEB $agebId',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF00BCD4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Datos demográficos
          _buildDemographicSection(),
          
          const SizedBox(height: 12),
          
          // Información adicional
          _buildAdditionalInfo(),
        ],
      ),
    );
  }

  Widget _buildDemographicSection() {
    final total = data['t'] ?? 0;
    final hombres = data['m'] ?? 0;
    final mujeres = data['f'] ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Datos Demográficos',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Total', total.toString(), Icons.people, Colors.green),
              _buildMetric('Hombres', hombres.toString(), Icons.man, Colors.blue),
              _buildMetric('Mujeres', mujeres.toString(), Icons.woman, Colors.pink),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdditionalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Información',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Área Geoestadística Básica',
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        if (data['superficie'] != null)
          Text(
            'Superficie: ${data['superficie']} m²',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
      ],
    );
  }

  Widget _buildMetric(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
