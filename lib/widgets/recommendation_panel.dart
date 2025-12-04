import 'package:flutter/material.dart';
import '../models/recommendation.dart';
import 'glossary_tooltip.dart';

class RecommendationPanel extends StatelessWidget {
  final List<Recommendation> recommendations;

  const RecommendationPanel({
    Key? key,
    required this.recommendations,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (recommendations.isEmpty) {
      return const Center(
        child: Text('No hay recomendaciones disponibles'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.lightbulb_outline, color: Colors.amber[600]),
            const SizedBox(width: 8),
            Text(
              'Recomendaciones',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            GlossaryHelpIcon(
              termKey: 'score_oportunidad',
              color: Colors.amber[600],
              size: 16,
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Score general
        _buildOverallScore(context),
        
        const SizedBox(height: 16),
        
        // Lista de recomendaciones
        ...recommendations.map((rec) => _buildRecommendationCard(rec)).toList(),
      ],
    );
  }

  Widget _buildOverallScore(BuildContext context) {
    final avgScore = recommendations.isNotEmpty
        ? recommendations.map((r) => r.score).reduce((a, b) => a + b) / recommendations.length
        : 0.0;

    Color scoreColor;
    String scoreLabel;
    String glossaryKey;
    
    if (avgScore >= 70) {
      scoreColor = Colors.green;
      scoreLabel = 'Excelente';
      glossaryKey = 'oportunidad_alta';
    } else if (avgScore >= 50) {
      scoreColor = Colors.orange;
      scoreLabel = 'Moderado';
      glossaryKey = 'oportunidad_moderada';
    } else {
      scoreColor = Colors.red;
      scoreLabel = 'Limitado';
      glossaryKey = 'oportunidad_baja';
    }

    return GestureDetector(
      onTap: () => showGlossaryModal(context, glossaryKey),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: scoreColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scoreColor.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: scoreColor,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  avgScore.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Score de Oportunidad',
                        style: TextStyle(
                          color: scoreColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GlossaryHelpIcon(
                        termKey: 'score_oportunidad',
                        color: scoreColor,
                        size: 14,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        scoreLabel,
                        style: TextStyle(
                          color: scoreColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.help_outline_rounded,
                        size: 14,
                        color: scoreColor.withOpacity(0.7),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Basado en ',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => showGlossaryModal(context, 'hhi'),
                        child: Text(
                          'concentración',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      Text(
                        ' y ',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => showGlossaryModal(context, 'pobtot'),
                        child: Text(
                          'demografía',
                          style: TextStyle(
                            color: Colors.orange[600],
                            fontSize: 12,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendationCard(Recommendation recommendation) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getTypeColor(recommendation.type).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getTypeColor(recommendation.type).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getTypeIcon(recommendation.type),
                color: _getTypeColor(recommendation.type),
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  recommendation.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(recommendation.type),
                    fontSize: 14,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getTypeColor(recommendation.type),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  recommendation.score.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          Text(
            recommendation.description,
            style: const TextStyle(fontSize: 13),
          ),
          
          if (recommendation.details.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...recommendation.details.map((detail) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    size: 14,
                    color: _getTypeColor(recommendation.type),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      detail,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      case 'info':
      default:
        return Colors.blue;
    }
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'info':
      default:
        return Icons.info;
    }
  }
}
