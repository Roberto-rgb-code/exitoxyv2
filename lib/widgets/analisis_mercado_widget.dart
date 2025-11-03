import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../services/denue_service.dart';
import '../services/market_structure_service.dart';

class AnalisisMercadoWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const AnalisisMercadoWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<AnalisisMercadoWidget> createState() => _AnalisisMercadoWidgetState();
}

class _AnalisisMercadoWidgetState extends State<AnalisisMercadoWidget> {
  List<Map<String, dynamic>> _businesses = [];
  Map<String, List<String>> _marketStructures = {};
  MarketStructureResult? _selectedAnalysis;
  String? _selectedActivity;
  bool _isLoading = false;
  String _errorMessage = '';

  // Parámetros del modelo
  double _paramA = 100.0;
  double _paramB = 1.0;
  double _paramC = 20.0;
  double _paramD = 0.5;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Cargar datos DENUE de diferentes tipos de negocios
      final allBusinesses = <Map<String, dynamic>>[];
      
      final businessTypes = [
        'Restaurantes',
        'Farmacias',
        'Supermercados',
        'Gasolineras',
        'Hospitales',
        'Escuelas',
      ];

      for (var type in businessTypes) {
        try {
          final businesses = await DenueService.fetchBusinesses(
            type,
            widget.latitude,
            widget.longitude,
            radius: 2000,
          );
          allBusinesses.addAll(businesses);
        } catch (e) {
          print('⚠️ Error cargando $type: $e');
        }
      }

      setState(() {
        _businesses = allBusinesses;
        _marketStructures = MarketStructureService.analyzeAllMarketStructures(allBusinesses);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error cargando datos: $e';
      });
    }
  }

  void _analyzeActivity(String activity) {
    setState(() {
      _selectedActivity = activity;
      _selectedAnalysis = MarketStructureService.analyzeActivity(activity, _businesses);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.blue[600]),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(color: Colors.grey[700]),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

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
                colors: [Colors.blue[700]!, Colors.blue[600]!],
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
                  child: const Icon(Icons.analytics, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Análisis de Estructura de Mercado',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Índice Herfindahl-Hirschman (HHI)',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_businesses.length} negocios',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Resumen de estructuras
          _buildMarketStructuresSummary(),
          const SizedBox(height: 16),

          // Selector de actividad
          if (_marketStructures.isNotEmpty) ...[
            _buildActivitySelector(),
            const SizedBox(height: 16),
          ],

          // Análisis detallado
          if (_selectedAnalysis != null) ...[
            _buildDetailedAnalysis(),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildMarketStructuresSummary() {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen de Estructuras de Mercado',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._marketStructures.entries.map((entry) {
              if (entry.value.isEmpty) return const SizedBox.shrink();
              
              final color = _getStructureColor(entry.key);
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${entry.key} (${entry.value.length} actividades)',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildActivitySelector() {
    final allActivities = <String>[];
    for (var activities in _marketStructures.values) {
      allActivities.addAll(activities);
    }

    if (allActivities.isEmpty) return const SizedBox.shrink();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar Actividad Económica',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedActivity,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              items: allActivities.map((activity) {
                return DropdownMenuItem(
                  value: activity,
                  child: Text(
                    activity,
                    style: GoogleFonts.poppins(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) _analyzeActivity(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedAnalysis() {
    final analysis = _selectedAnalysis!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Métricas del mercado
        Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Métricas del Mercado',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'Número de Empresas',
                        analysis.nFirms.toString(),
                        Icons.business,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'HHI',
                        analysis.hhi.toStringAsFixed(2),
                        Icons.trending_up,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        'CR4',
                        '${(analysis.cr4 * 100).toStringAsFixed(1)}%',
                        Icons.pie_chart,
                        Colors.purple,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        'Estructura',
                        analysis.structure,
                        Icons.category,
                        _getStructureColor(analysis.structure),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Gráfico de concentración
        _buildConcentrationChart(),
        const SizedBox(height: 16),

        // Modelos económicos
        _buildEconomicModels(),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildConcentrationChart() {
    if (_selectedAnalysis == null || _selectedAnalysis!.firms.isEmpty) {
      return const SizedBox.shrink();
    }

    final firms = _selectedAnalysis!.firms;
    final sortedFirms = List<Map<String, dynamic>>.from(firms)
      ..sort((a, b) => (b['participacion'] as double).compareTo(a['participacion'] as double));

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Concentración del Mercado',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelStyle: GoogleFonts.poppins(fontSize: 10),
                ),
                primaryYAxis: NumericAxis(
                  labelStyle: GoogleFonts.poppins(fontSize: 10),
                  title: AxisTitle(
                    text: 'Participación (%)',
                    textStyle: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
                series: <CartesianSeries>[
                  ColumnSeries<Map<String, dynamic>, String>(
                    dataSource: sortedFirms.take(10).toList(),
                    xValueMapper: (data, index) => 'E${index + 1}',
                    yValueMapper: (data, _) => (data['participacion'] as double) * 100,
                    color: Colors.blue[600],
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Top 10 empresas por participación de mercado',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEconomicModels() {
    if (_selectedAnalysis == null) return const SizedBox.shrink();

    final structure = _selectedAnalysis!.structure;
    final nFirms = _selectedAnalysis!.nFirms;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Modelos Económicos',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Parámetros ajustables
            _buildModelParameters(),
            const SizedBox(height: 16),

            // Resultados del modelo
            _buildModelResults(structure, nFirms),
          ],
        ),
      ),
    );
  }

  Widget _buildModelParameters() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Parámetros del Modelo',
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Demanda máxima (a)', style: GoogleFonts.poppins(fontSize: 12)),
                  Slider(
                    value: _paramA,
                    min: 50,
                    max: 200,
                    divisions: 30,
                    label: _paramA.toStringAsFixed(1),
                    onChanged: (value) => setState(() => _paramA = value),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pendiente (b)', style: GoogleFonts.poppins(fontSize: 12)),
                  Slider(
                    value: _paramB,
                    min: 0.1,
                    max: 5.0,
                    divisions: 49,
                    label: _paramB.toStringAsFixed(2),
                    onChanged: (value) => setState(() => _paramB = value),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Costo marginal (c)', style: GoogleFonts.poppins(fontSize: 12)),
                  Slider(
                    value: _paramC,
                    min: 10,
                    max: 50,
                    divisions: 40,
                    label: _paramC.toStringAsFixed(1),
                    onChanged: (value) => setState(() => _paramC = value),
                  ),
                ],
              ),
            ),
            if (_selectedAnalysis?.structure == 'Competencia Monopolística') ...[
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Diferenciación (d)', style: GoogleFonts.poppins(fontSize: 12)),
                    Slider(
                      value: _paramD,
                      min: 0.0,
                      max: 1.0,
                      divisions: 20,
                      label: _paramD.toStringAsFixed(2),
                      onChanged: (value) => setState(() => _paramD = value),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildModelResults(String structure, int nFirms) {
    EconomicModelResult? result;

    switch (structure) {
      case 'Oligopolio':
        result = MarketStructureService.cournotModel(nFirms, _paramA, _paramB, _paramC);
        break;
      case 'Competencia Perfecta':
        result = MarketStructureService.perfectCompetitionModel(_paramA, _paramB, _paramC);
        break;
      case 'Competencia Monopolística':
        result = MarketStructureService.monopolisticCompetitionModel(
          nFirms, _paramA, _paramB, _paramC, _paramD,
        );
        break;
      case 'Monopolio':
        result = MarketStructureService.monopolyModel(_paramA, _paramB, _paramC);
        break;
    }

    if (result == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modelo: ${result.modelName}',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...result.results.entries.map((entry) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatResultKey(entry.key),
                    style: GoogleFonts.poppins(fontSize: 14),
                  ),
                  Text(
                    entry.value.toStringAsFixed(2),
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  String _formatResultKey(String key) {
    final Map<String, String> translations = {
      'Q_total': 'Cantidad Total',
      'P_equilibrio': 'Precio de Equilibrio',
      'q_individual': 'Cantidad por Empresa',
      'q_lider': 'Cantidad Líder',
      'q_seguidor': 'Cantidad Seguidor',
      'beneficio_individual': 'Beneficio por Empresa',
      'beneficio_lider': 'Beneficio Líder',
      'beneficio_seguidor': 'Beneficio Seguidor',
      'beneficio_total': 'Beneficio Total',
      'beneficio': 'Beneficio',
    };
    return translations[key] ?? key;
  }

  Color _getStructureColor(String structure) {
    switch (structure) {
      case 'Monopolio':
        return Colors.red[700]!;
      case 'Oligopolio':
        return Colors.orange[700]!;
      case 'Competencia Monopolística':
        return Colors.blue[700]!;
      case 'Competencia Perfecta':
        return Colors.green[700]!;
      default:
        return Colors.grey;
    }
  }
}

