import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../services/denue_service.dart';
import '../services/market_structure_service.dart';
import '../services/glossary_service.dart';

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
                      Row(
                        children: [
                          Text(
                            'Análisis de Estructura de Mercado',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildHelpIcon(context, 'estructura_mercado'),
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            'Índice Herfindahl-Hirschman (',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => _showTermDefinition(context, 'hhi'),
                            child: Text(
                              'HHI',
                              style: GoogleFonts.poppins(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                          Text(
                            ')',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _buildHelpIcon(context, 'hhi', color: Colors.white70),
                        ],
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
                      child: InkWell(
                        onTap: () => _showStructureDetailModal(context, entry.key, entry.value),
                        child: Text(
                          '${entry.key} (${entry.value.length} actividades)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
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
              isExpanded: true,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
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
              selectedItemBuilder: (context) {
                return allActivities.map((activity) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      activity,
                      style: GoogleFonts.poppins(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }).toList();
              },
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
                      child: _buildMetricCardWithHelp(
                        context,
                        'Número de Empresas',
                        analysis.nFirms.toString(),
                        Icons.business,
                        Colors.blue,
                        null, // Sin término de glosario
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCardWithHelp(
                        context,
                        'HHI',
                        analysis.hhi.toStringAsFixed(2),
                        Icons.trending_up,
                        Colors.orange,
                        'hhi',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCardWithHelp(
                        context,
                        'CR4',
                        '${(analysis.cr4 * 100).toStringAsFixed(1)}%',
                        Icons.pie_chart,
                        Colors.purple,
                        'cr4',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCardWithHelp(
                        context,
                        'Estructura',
                        analysis.structure,
                        Icons.category,
                        _getStructureColor(analysis.structure),
                        'estructura_mercado',
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

  /// Construye una tarjeta de métrica con icono de ayuda del glosario
  Widget _buildMetricCardWithHelp(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    String? glossaryKey,
  ) {
    return InkWell(
      onTap: () => _showMetricDetailModal(context, label, value, icon, color),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                if (glossaryKey != null) ...[
                  const SizedBox(width: 4),
                  GestureDetector(
                    onTap: () => _showTermDefinition(context, glossaryKey),
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.help_outline_rounded,
                        size: 10,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    label,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
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

  void _showStructureDetailModal(BuildContext context, String structure, List<String> activities) {
    final color = _getStructureColor(structure);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          structure,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${activities.length} actividades económicas',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Actividades:',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: activities.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              _analyzeActivity(activities[index]);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.business, color: color, size: 20),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      activities[index],
                                      style: GoogleFonts.poppins(fontSize: 14),
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showMetricDetailModal(BuildContext context, String label, String value, IconData icon, Color color) {
    if (_selectedAnalysis == null) return;

    final analysis = _selectedAnalysis!;
    String description = '';
    Map<String, String> additionalInfo = {};

    switch (label) {
      case 'Número de Empresas':
        description = 'Cantidad total de empresas que operan en esta actividad económica en el área analizada.';
        additionalInfo = {
          'Actividad': analysis.actividad,
          'Empresas únicas': '${analysis.nFirms}',
        };
        break;
      case 'HHI':
        description = 'Índice Herfindahl-Hirschman (HHI) mide la concentración del mercado. Valores más altos indican mayor concentración.';
        additionalInfo = {
          'Valor HHI': analysis.hhi.toStringAsFixed(2),
          'Interpretación': _getHHIInterpretation(analysis.hhi),
        };
        break;
      case 'CR4':
        description = 'Ratio de concentración de las 4 empresas más grandes. Mide qué porcentaje del mercado controlan las 4 principales empresas.';
        additionalInfo = {
          'CR4': '${(analysis.cr4 * 100).toStringAsFixed(1)}%',
          'Interpretación': _getCR4Interpretation(analysis.cr4),
        };
        break;
      case 'Estructura':
        description = 'Tipo de estructura de mercado determinada por los índices HHI y CR4.';
        additionalInfo = {
          'Estructura': analysis.structure,
          'HHI': analysis.hhi.toStringAsFixed(2),
          'CR4': '${(analysis.cr4 * 100).toStringAsFixed(1)}%',
        };
        break;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          value,
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                'Descripción',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Información Adicional',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              ...additionalInfo.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        entry.value,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  String _getHHIInterpretation(double hhi) {
    if (hhi > 7500) return 'Muy alta concentración (Monopolio)';
    if (hhi > 2500) return 'Alta concentración (Oligopolio)';
    if (hhi > 1500) return 'Concentración moderada (Competencia Monopolística)';
    return 'Baja concentración (Competencia Perfecta)';
  }

  String _getCR4Interpretation(double cr4) {
    if (cr4 > 0.9) return 'Muy alta concentración';
    if (cr4 > 0.6) return 'Alta concentración';
    if (cr4 > 0.4) return 'Concentración moderada';
    return 'Baja concentración';
  }

  /// Construye un icono de ayuda (?) para términos del glosario
  Widget _buildHelpIcon(BuildContext context, String termKey, {Color? color}) {
    return GestureDetector(
      onTap: () => _showTermDefinition(context, termKey),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: (color ?? Colors.blue[700])!.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: (color ?? Colors.blue[700])!.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.help_outline_rounded,
          size: 12,
          color: color ?? Colors.blue[700],
        ),
      ),
    );
  }

  /// Muestra la definición de un término del glosario
  void _showTermDefinition(BuildContext context, String termKey) {
    final term = GlossaryService.getTerm(termKey);
    if (term == null) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: Colors.blue[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          term.term,
                          style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (term.fullName != term.term)
                          Text(
                            term.fullName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            
            // Definición
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  term.definition,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            
            // Ejemplo
            if (term.example != null) 
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.lightbulb_outline, color: Colors.amber[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          term.example!,
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

