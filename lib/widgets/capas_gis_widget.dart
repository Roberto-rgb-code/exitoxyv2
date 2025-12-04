import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/postgres_gis_service.dart';
import 'glossary_tooltip.dart';

class CapasGisWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const CapasGisWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<CapasGisWidget> createState() => _CapasGisWidgetState();
}

class _CapasGisWidgetState extends State<CapasGisWidget> {
  final PostgresGisService _gisService = PostgresGisService();
  Map<String, dynamic>? _capasInfo;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadCapasInfo();
  }

  Future<void> _loadCapasInfo() async {
    setState(() => _isLoading = true);

    try {
      final capas = await _gisService.analyzeAllLayers();
      
      setState(() {
        _capasInfo = {
          'total': capas.length,
          'capas': capas,
        };
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error cargando información de capas: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.teal[600],
        ),
      );
    }

    if (_capasInfo == null) {
      return Center(
        child: Text(
          'No se pudieron cargar las capas GIS',
          style: GoogleFonts.poppins(color: Colors.grey[600]),
        ),
      );
    }

    final capas = _capasInfo!['capas'] as List;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.teal[700]!, Colors.teal[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
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
                    Icons.layers,
                    color: Colors.white,
                    size: 24,
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
                            'Capas GIS ',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => showGlossaryModal(context, 'postgis'),
                            child: Row(
                              children: [
                                Text(
                                  'PostGIS',
                                  style: GoogleFonts.poppins(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GlossaryHelpIcon(
                                  termKey: 'postgis',
                                  color: Colors.white70,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            '${capas.length} capas espaciales disponibles',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          GlossaryHelpIcon(
                            termKey: 'geojson',
                            color: Colors.white60,
                            size: 12,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Lista de capas
          ...capas.where((capa) => capa['name'] != 'spatial_ref_sys').map((capa) {
            final nombre = capa['name'] as String;
            final registros = capa['record_count'] as int;
            final geometria = capa['geometry'] as Map<String, dynamic>?;
            final columns = capa['columns'] as List;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.teal[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            geometria != null 
                                ? _getGeometryIcon(geometria['type'] as String)
                                : Icons.table_chart,
                            color: Colors.teal[700],
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                nombre,
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                '${_formatNumber(registros)} registros',
                                style: GoogleFonts.poppins(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (geometria != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.map, color: Colors.blue[700], size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'Geometría Espacial',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            _buildInfoRow('Tipo', geometria['type'] as String),
                            _buildInfoRow('SRID', geometria['srid'] as String),
                            _buildInfoRow('Dimensión', geometria['dimension'] as String),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      '${columns.length} columnas • ${geometria != null ? "Con geometría" : "Sin geometría"}',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[700],
              ),
            ),
          ),
          Text(
            ': $value',
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getGeometryIcon(String type) {
    switch (type.toUpperCase()) {
      case 'POINT':
      case 'MULTIPOINT':
        return Icons.location_on;
      case 'LINESTRING':
      case 'MULTILINESTRING':
        return Icons.show_chart;
      case 'POLYGON':
      case 'MULTIPOLYGON':
        return Icons.shape_line;
      default:
        return Icons.map;
    }
  }

  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

