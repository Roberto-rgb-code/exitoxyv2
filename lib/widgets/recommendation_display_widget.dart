import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/recommendation_service.dart';
import 'street_view_widget.dart';

class RecommendationDisplayWidget extends StatelessWidget {
  final LocationRecommendation recommendation;

  const RecommendationDisplayWidget({
    super.key,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue[700]!,
                  Colors.blue[600]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 24,
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
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            color: Colors.amber[300],
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Score: ${recommendation.overallScore.toStringAsFixed(1)}/100',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
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

          // Scores
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Score general
                _buildScoreCard(
                  title: 'Score General',
                  score: recommendation.overallScore,
                  color: _getScoreColor(recommendation.overallScore),
                  icon: Icons.analytics,
                ),
                
                const SizedBox(height: 16),
                
                // Scores específicos
                Row(
                  children: [
                    Expanded(
                      child: _buildScoreCard(
                        title: 'Seguridad',
                        score: recommendation.safetyScore,
                        color: _getScoreColor(recommendation.safetyScore),
                        icon: Icons.security,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildScoreCard(
                        title: 'Servicios',
                        score: recommendation.servicesScore,
                        color: _getScoreColor(recommendation.servicesScore),
                        icon: Icons.local_hospital,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                Row(
                  children: [
                    Expanded(
                      child: _buildScoreCard(
                        title: 'Transporte',
                        score: recommendation.transportScore,
                        color: _getScoreColor(recommendation.transportScore),
                        icon: Icons.directions_bus,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildScoreCard(
                        title: 'Delitos',
                        score: recommendation.crimeCount > 0 
                            ? (100 - (recommendation.crimeCount * 2).clamp(0, 100)).toDouble()
                            : 100.0,
                        color: recommendation.crimeCount > 0 
                            ? Colors.red[300]! 
                            : Colors.green[300]!,
                        icon: Icons.warning,
                        subtitle: '${recommendation.crimeCount} reportes',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Street View
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: StreetViewWidget(
              latitude: recommendation.latitude,
              longitude: recommendation.longitude,
              locationName: recommendation.locationName,
            ),
          ),

          const SizedBox(height: 20),

          // Servicios cercanos
          if (recommendation.nearbyServices.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Servicios Cercanos',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: recommendation.nearbyServices.entries.map((entry) {
                      return _buildServiceChip(entry.key, entry.value);
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Recomendaciones
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recomendaciones',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                ...recommendation.recommendations.map((rec) => 
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rec,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildScoreCard({
    required String title,
    required double score,
    required Color color,
    required IconData icon,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '${score.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildServiceChip(String service, int count) {
    final serviceNames = {
      'hospital': 'Hospitales',
      'school': 'Escuelas',
      'pharmacy': 'Farmacias',
      'gas_station': 'Gasolineras',
      'police': 'Policía',
      'fire_station': 'Bomberos',
      'transit_station': 'Transporte',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getServiceIcon(service),
            size: 16,
            color: Colors.blue[700],
          ),
          const SizedBox(width: 4),
          Text(
            '${serviceNames[service] ?? service}: $count',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String service) {
    switch (service) {
      case 'hospital':
        return Icons.local_hospital;
      case 'school':
        return Icons.school;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'gas_station':
        return Icons.local_gas_station;
      case 'police':
        return Icons.local_police;
      case 'fire_station':
        return Icons.local_fire_department;
      case 'transit_station':
        return Icons.directions_bus;
      default:
        return Icons.place;
    }
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green[400]!;
    if (score >= 60) return Colors.orange[400]!;
    if (score >= 40) return Colors.amber[400]!;
    return Colors.red[400]!;
  }
}
