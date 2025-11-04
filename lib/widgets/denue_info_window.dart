import 'package:flutter/material.dart';
import 'package:kitit_v2/models/concentration_result.dart';
import 'package:kitit_v2/widgets/custom_info_window.dart';

class DenueInfoWindow extends StatelessWidget {
  final String name;
  final String? description;
  final String activity;
  final ConcentrationResult? concentrationResult;
  final CustomInfoWindowController? controller;

  const DenueInfoWindow({
    Key? key,
    required this.name,
    this.description,
    required this.activity,
    this.concentrationResult,
    this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con nombre, nivel de concentración y botón cerrar
          Row(
            children: [
              Icon(Icons.storefront, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (concentrationResult != null)
                _buildConcentrationBadge(concentrationResult!),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.black54, size: 20),
                onPressed: () {
                  controller?.hideInfoWindow?.call();
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Actividad económica
          Row(
            children: [
              Icon(Icons.business, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  activity,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          
          if (description != null && description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              description!,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          
          if (concentrationResult != null) ...[
            const SizedBox(height: 12),
            _buildConcentrationDetails(concentrationResult!),
          ],
        ],
      ),
    );
  }

  Widget _buildConcentrationBadge(ConcentrationResult result) {
    final color = Color(result.color);
    final level = _getLevelLabel(result.level);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildConcentrationDetails(ConcentrationResult result) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Índice de Concentración',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildConcentrationMetric('HHI', result.hhi.toStringAsFixed(0)),
              _buildConcentrationMetric('CR4', '${result.cr4.toStringAsFixed(1)}%'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConcentrationMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  String _getLevelLabel(String level) {
    switch (level) {
      case 'low':
        return 'Baja';
      case 'moderate':
        return 'Moderada';
      case 'high':
        return 'Alta';
      case 'veryHigh':
        return 'Muy alta';
      default:
        return '—';
    }
  }
}
