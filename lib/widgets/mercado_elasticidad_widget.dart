import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:syncfusion_flutter_charts/charts.dart';

import '../services/denue_service.dart';
import '../services/elasticity_service.dart';
import '../services/postgres_gis_service.dart';

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
  List<Map<String, dynamic>> _businesses = [];
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
        _businesses = allBusinesses;
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
                      Text(
                        'Análisis de Elasticidad',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Precio, Cruzada e Ingreso',
                        style: GoogleFonts.poppins(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
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
                Text(
                  'Elasticidad Precio-Espacial',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                Text(
                  'Elasticidad Cruzada (Sustitutos)',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
                Text(
                  'Elasticidad Ingreso (Demanda)',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
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
            Text(
              'Elasticidad ingreso > 1: Bien normal de lujo | 0-1: Bien normal necesario | < 0: Bien inferior',
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
}

