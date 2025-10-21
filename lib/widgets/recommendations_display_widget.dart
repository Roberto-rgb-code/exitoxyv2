import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/recommendation.dart';

class RecommendationsDisplayWidget extends StatelessWidget {
  final Recommendation recommendation;

  const RecommendationsDisplayWidget({
    super.key,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: _getScoreColor(recommendation.score).withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header con score
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getScoreColor(recommendation.score).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.location_on,
                  color: _getScoreColor(recommendation.score),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.locationName,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Score: ${recommendation.score.toStringAsFixed(1)}/100',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: _getScoreColor(recommendation.score),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getScoreColor(recommendation.score),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _getScoreText(recommendation.score),
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Factores de evaluación
          if (recommendation.factors.isNotEmpty) ...[
            Text(
              'Factores de Evaluación:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            _buildFactorRow(
              'Seguridad',
              recommendation.factors['safety'] ?? 0.0,
              Icons.security,
              colorScheme,
            ),
            const SizedBox(height: 4),
            _buildFactorRow(
              'Servicios',
              recommendation.factors['services'] ?? 0.0,
              Icons.business,
              colorScheme,
            ),
            const SizedBox(height: 4),
            _buildFactorRow(
              'Transporte',
              recommendation.factors['transport'] ?? 0.0,
              Icons.directions_transit,
              colorScheme,
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Información adicional
          if (recommendation.description.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                recommendation.description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: colorScheme.onSurface.withOpacity(0.8),
                ),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildFactorRow(String label, double score, IconData icon, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
        Text(
          '${score.toStringAsFixed(1)}/100',
          style: GoogleFonts.poppins(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _getScoreColor(score),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 60,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: (score / 100).clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: _getScoreColor(score),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green[600]!;
    if (score >= 60) return Colors.orange[600]!;
    if (score >= 40) return Colors.amber[600]!;
    return Colors.red[600]!;
  }

  String _getScoreText(double score) {
    if (score >= 80) return 'EXCELENTE';
    if (score >= 60) return 'BUENO';
    if (score >= 40) return 'REGULAR';
    return 'BAJO';
  }
}
