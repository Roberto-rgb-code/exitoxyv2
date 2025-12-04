import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../services/denue_service.dart';
import '../services/elasticity_service.dart';
import '../services/postgres_gis_service.dart';
import '../services/glossary_service.dart';

class MercadoElasticidadWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const MercadoElasticidadWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<MercadoElasticidadWidget> createState() => _MercadoElasticidadWidgetState();
}

class _MercadoElasticidadWidgetState extends State<MercadoElasticidadWidget> {
  SpatialElasticityResult? _spatialElasticity;
  List<CrossElasticityResult> _crossElasticities = [];
  Map<String, IncomeElasticityResult> _incomeElasticities = {};
  bool _isLoading = false;
  String _errorMessage = '';
  double _population = 0;
  double _activePopulation = 0;
  final double _radiusKm = 2.0;

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
      // Cargar datos DENUE
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
            radius: (_radiusKm * 1000).toInt(),
          );
          allBusinesses.addAll(businesses);
        } catch (e) {
          print('⚠️ Error cargando $type: $e');
        }
      }

      // Cargar datos demográficos para elasticidad ingreso
      final postgisService = PostgresGisService();
      try {
        final agebData = await postgisService.getAgebInBounds(
          minLat: widget.latitude - 0.018,
          minLng: widget.longitude - 0.018,
          maxLat: widget.latitude + 0.018,
          maxLng: widget.longitude + 0.018,
          limit: 100,
        );

        // Calcular población total y activa
        int totalPop = 0;
        int totalActive = 0;
        for (var data in agebData) {
          totalPop += (data['pobtot'] ?? 0) as int;
          totalActive += (data['pea'] ?? 0) as int;
        }
        _population = totalPop.toDouble();
        _activePopulation = totalActive.toDouble();
      } catch (e) {
        print('⚠️ Error cargando datos demográficos: $e');
        // Valores por defecto
        _population = 10000.0;
        _activePopulation = 5000.0;
      }

      // Calcular elasticidades
      final spatial = ElasticityService.analyzeSpatialPriceElasticity(allBusinesses, _radiusKm);
      final cross = ElasticityService.analyzeCrossElasticity(allBusinesses);
      final income = ElasticityService.analyzeAllIncomeElasticities(
        allBusinesses,
        _population,
        _activePopulation,
        _radiusKm,
      );

      setState(() {
        _spatialElasticity = spatial;
        _crossElasticities = cross;
        _incomeElasticities = income;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error cargando datos: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(color: Colors.green[600]),
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
                colors: [Colors.green[700]!, Colors.green[600]!],
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
                  child: const Icon(Icons.trending_up, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Análisis de Elasticidad',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildHelpIcon(context, 'elasticidad_precio', color: Colors.white70),
                        ],
                      ),
                      Row(
                        children: [
                          _buildTermLink(context, 'Precio', 'elasticidad_precio'),
                          Text(', ', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                          _buildTermLink(context, 'Cruzada', 'elasticidad_cruzada'),
                          Text(' e ', style: GoogleFonts.poppins(color: Colors.white70, fontSize: 12)),
                          _buildTermLink(context, 'Ingreso', 'elasticidad_ingreso'),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Elasticidad precio-espacial
          if (_spatialElasticity != null) ...[
            _buildSpatialElasticity(),
            const SizedBox(height: 16),
          ],

          // Elasticidad cruzada
          if (_crossElasticities.isNotEmpty) ...[
            _buildCrossElasticity(),
            const SizedBox(height: 16),
          ],

          // Elasticidad ingreso
          if (_incomeElasticities.isNotEmpty) ...[
            _buildIncomeElasticity(),
          ],
        ],
      ),
    );
  }

  Widget _buildSpatialElasticity() {
    final spatial = _spatialElasticity!;

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.map, color: Colors.blue[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Elasticidad Precio-Espacial',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _buildHelpIcon(context, 'elasticidad_espacial', color: Colors.blue[700]),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildElasticityMetric(
                    'Densidad',
                    '${spatial.density.toStringAsFixed(2)}\nnegocios/km²',
                    Icons.density_medium,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildElasticityMetric(
                    'Índice Competencia',
                    '${(spatial.competitionIndex * 100).toStringAsFixed(1)}%',
                    Icons.people,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Elasticidad Precio-Espacial',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'E = ${spatial.elasticity.toStringAsFixed(4)}',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    spatial.elasticity < -0.5 ? Icons.trending_down : Icons.trending_up,
                    size: 32,
                    color: Colors.blue[700],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Interpretación: ${spatial.elasticity < -0.5 ? "Alta" : "Moderada"} sensibilidad a cambios de precio por proximidad geográfica',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCrossElasticity() {
    final topCross = _crossElasticities.take(10).toList();

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.swap_horiz, color: Colors.purple[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Elasticidad Cruzada ',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showTermDefinition(context, 'bienes_sustitutos'),
                        child: Text(
                          '(Sustitutos)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.purple[400],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildHelpIcon(context, 'elasticidad_cruzada', color: Colors.purple[700]),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 300,
              child: ListView.builder(
                itemCount: topCross.length,
                itemBuilder: (context, index) {
                  final result = topCross[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    color: Colors.purple[50],
                    child: InkWell(
                      onTap: () => _showCrossElasticityDetailModal(context, result, index + 1),
                      borderRadius: BorderRadius.circular(8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.purple[700],
                          child: Text(
                            'E${index + 1}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text(
                          '${_truncateText(result.activity1, 20)} ↔ ${_truncateText(result.activity2, 20)}',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Distancia: ${result.distance.toStringAsFixed(2)} km',
                          style: GoogleFonts.poppins(fontSize: 11),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'E = ${result.elasticity.toStringAsFixed(3)}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.purple[700],
                              ),
                            ),
                            Text(
                              '${(result.substitutionIndex * 100).toStringAsFixed(0)}%',
                              style: GoogleFonts.poppins(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Top 10 pares de actividades con mayor elasticidad cruzada (bienes sustitutos)',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeElasticity() {
    final incomeList = _incomeElasticities.values.toList()
      ..sort((a, b) => b.elasticity.compareTo(a.elasticity));

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.attach_money, color: Colors.green[700], size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        'Elasticidad Ingreso ',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => _showTermDefinition(context, 'bien_normal'),
                        child: Text(
                          '(Demanda)',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.green[400],
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildHelpIcon(context, 'elasticidad_ingreso', color: Colors.green[700]),
              ],
            ),
            const SizedBox(height: 16),

            // Gráfico de barras
            SizedBox(
              height: 300,
              child: SfCartesianChart(
                primaryXAxis: CategoryAxis(
                  labelStyle: GoogleFonts.poppins(fontSize: 10),
                  labelRotation: -45,
                ),
                primaryYAxis: NumericAxis(
                  labelStyle: GoogleFonts.poppins(fontSize: 10),
                  title: AxisTitle(
                    text: 'Elasticidad Ingreso',
                    textStyle: GoogleFonts.poppins(fontSize: 12),
                  ),
                ),
                series: <CartesianSeries>[
                  ColumnSeries<IncomeElasticityResult, String>(
                    dataSource: incomeList.take(10).toList(),
                    xValueMapper: (data, index) => _truncateText(data.activity, 15),
                    yValueMapper: (data, _) => data.elasticity,
                    color: Colors.green[600],
                    dataLabelSettings: DataLabelSettings(
                      isVisible: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Lista detallada
            ...incomeList.take(5).map((result) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                color: Colors.green[50],
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.green[700],
                    child: Icon(Icons.trending_up, color: Colors.white, size: 20),
                  ),
                  title: Text(
                    result.activity,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    'Densidad: ${result.businessDensity.toStringAsFixed(2)} negocios/km²',
                    style: GoogleFonts.poppins(fontSize: 11),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'E = ${result.elasticity.toStringAsFixed(3)}',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700],
                        ),
                      ),
                      Text(
                        _getElasticityType(result.elasticity),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.green[700]),
                      const SizedBox(width: 8),
                      Text(
                        'Interpretación:',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      _buildElasticityBadge(context, 'E > 1', 'Bien de lujo', 'bien_normal', Colors.purple),
                      _buildElasticityBadge(context, '0 < E < 1', 'Bien necesario', 'bien_normal', Colors.blue),
                      _buildElasticityBadge(context, 'E < 0', 'Bien inferior', 'bien_inferior', Colors.orange),
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

  Widget _buildElasticityMetric(String label, String value, IconData icon, Color color) {
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
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
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

  String _truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }

  String _getElasticityType(double elasticity) {
    if (elasticity > 1.0) return 'Lujo';
    if (elasticity > 0) return 'Necesario';
    return 'Inferior';
  }

  void _showCrossElasticityDetailModal(BuildContext context, CrossElasticityResult result, int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
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
                    CircleAvatar(
                      backgroundColor: Colors.purple[700],
                      radius: 24,
                      child: Text(
                        'E$index',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Elasticidad Cruzada',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Bienes Sustitutos',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.purple[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.purple[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.swap_horiz, color: Colors.purple[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Par de Actividades',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildActivityRow('Actividad 1', result.activity1),
                      const SizedBox(height: 8),
                      Icon(Icons.arrow_downward, color: Colors.purple[400], size: 20),
                      const SizedBox(height: 8),
                      _buildActivityRow('Actividad 2', result.activity2),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDetailItem('Elasticidad', 'E = ${result.elasticity.toStringAsFixed(3)}'),
                    _buildDetailItem('Distancia', '${result.distance.toStringAsFixed(2)} km'),
                    _buildDetailItem('Índice Sustitución', '${(result.substitutionIndex * 100).toStringAsFixed(0)}%'),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interpretación',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getCrossElasticityInterpretation(result.elasticity),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityRow(String label, String activity) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.business, color: Colors.purple[700], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  activity,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.purple[700],
          ),
        ),
      ],
    );
  }

  String _getCrossElasticityInterpretation(double elasticity) {
    if (elasticity > 0.5) {
      return 'Alta elasticidad cruzada: Estas actividades son fuertes sustitutos. Un cambio en el precio de una afecta significativamente la demanda de la otra.';
    } else if (elasticity > 0.2) {
      return 'Moderada elasticidad cruzada: Estas actividades son sustitutos moderados. Existe cierta relación entre sus demandas.';
    } else {
      return 'Baja elasticidad cruzada: Estas actividades tienen poca relación como sustitutos. Sus demandas son relativamente independientes.';
    }
  }

  /// Construye un badge de elasticidad con tooltip
  Widget _buildElasticityBadge(BuildContext context, String formula, String label, String termKey, Color color) {
    return GestureDetector(
      onTap: () => _showTermDefinition(context, termKey),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$formula: ',
              style: GoogleFonts.poppins(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 10,
                color: color,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.help_outline_rounded, size: 12, color: color),
          ],
        ),
      ),
    );
  }

  /// Construye un icono de ayuda (?) para términos del glosario
  Widget _buildHelpIcon(BuildContext context, String termKey, {Color? color}) {
    return GestureDetector(
      onTap: () => _showTermDefinition(context, termKey),
      child: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: (color ?? Colors.green[700])!.withOpacity(0.2),
          shape: BoxShape.circle,
          border: Border.all(
            color: (color ?? Colors.green[700])!.withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Icon(
          Icons.help_outline_rounded,
          size: 12,
          color: color ?? Colors.green[700],
        ),
      ),
    );
  }

  /// Construye un texto con link al glosario
  Widget _buildTermLink(BuildContext context, String displayText, String termKey) {
    return GestureDetector(
      onTap: () => _showTermDefinition(context, termKey),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            displayText,
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              decoration: TextDecoration.underline,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.help_outline_rounded,
            size: 12,
            color: Colors.white70,
          ),
        ],
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
                      color: Colors.green[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.trending_up,
                      color: Colors.green[700],
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
            
            // Badge de categoría
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      term.category,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.green[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 18, color: Colors.green[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Definición',
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.green[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      term.definition,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ejemplo',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.amber[700],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              term.example!,
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
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

