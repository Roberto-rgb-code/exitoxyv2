import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/delitos_service.dart';
import '../services/recommendation_service.dart';
import '../services/facebook_marketplace_service.dart';
import '../services/denue_service.dart';
import '../models/delito_model.dart';
import '../models/recommendation.dart';
import 'denue_businesses_widget.dart';
import 'map3d_widget.dart';
import 'recommendations_display_widget.dart';
import 'delitos_table_widget.dart';
import 'marketplace_listings_widget.dart';

class IntegratedAnalysisPage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;

  const IntegratedAnalysisPage({
    Key? key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  }) : super(key: key);

  @override
  State<IntegratedAnalysisPage> createState() => _IntegratedAnalysisPageState();
}

class _IntegratedAnalysisPageState extends State<IntegratedAnalysisPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final DelitosService _delitosService = DelitosService();
  final RecommendationService _recommendationService = RecommendationService();
  final FacebookMarketplaceService _marketplaceService = FacebookMarketplaceService();
  
  List<Recommendation> _recommendations = [];
  List<dynamic> _marketplaceListings = [];
  List<Map<String, dynamic>> _denueBusinesses = [];
  Map<String, dynamic>? _visorUrbanoData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadAllDataAsync();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllDataAsync() async {
    setState(() => _isLoading = true);
    
    // Cargar datos en segundo plano
    _loadBackgroundData();
    
    setState(() => _isLoading = false);
  }

  Future<void> _loadBackgroundData() async {
    try {
      // Cargar delitos
      await _delitosService.loadDelitosFromCsv();
      
      // Generar recomendaciones
      _recommendations = await _recommendationService.generateRecommendations(
        latitude: widget.latitude,
        longitude: widget.longitude,
        locationName: widget.locationName,
      );
      
      if (mounted) setState(() {});
    } catch (e) {
      print('Error cargando datos en segundo plano: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis Integrado'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
               tabs: const [
                 Tab(icon: Icon(Icons.warning), text: 'Delitos'),
                 Tab(icon: Icon(Icons.business), text: 'DENUE'),
                 Tab(icon: Icon(Icons.store), text: 'Marketplace'),
                 Tab(icon: Icon(Icons.lightbulb), text: 'Recomendaciones'),
                 Tab(icon: Icon(Icons.view_in_ar), text: '3D'),
               ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
         children: [
           _buildDelitosContent(colorScheme),
           DenueBusinessesWidget(
             latitude: widget.latitude,
             longitude: widget.longitude,
             businessType: 'Restaurantes',
           ),
           MarketplaceListingsWidget(
             latitude: widget.latitude,
             longitude: widget.longitude,
           ),
           _buildRecommendationsContent(colorScheme),
           Map3DWidget(
             latitude: widget.latitude,
             longitude: widget.longitude,
             locationName: widget.locationName,
           ),
         ],
      ),
    );
  }

  Widget _buildDelitosContent(ColorScheme colorScheme) {
    // Obtener delitos para el área
    final delitos = _delitosService.getDelitosByLocation(
      latitude: widget.latitude,
      longitude: widget.longitude,
      radiusMeters: 2000,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header con estadísticas
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.red[700]!,
                  Colors.red[600]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.warning,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Capa de Delitos',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Datos del IIEG - ZMG',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
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
                        '${delitos.length} delitos',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Tabla de delitos
          if (delitos.isNotEmpty) ...[
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: DelitosTableWidget(delitos: delitos),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.green[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Se encontraron 0 delitos en el área',
                      style: GoogleFonts.poppins(
                        color: Colors.green[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendationsContent(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.amber[700]!,
                  Colors.amber[600]!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.lightbulb,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recomendaciones',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Análisis inteligente de ubicación',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.8),
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
                        '${_recommendations.length} recomendaciones',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Lista de recomendaciones
          if (_recommendations.isNotEmpty) ...[
            ..._recommendations.map((recommendation) => 
              RecommendationsDisplayWidget(recommendation: recommendation)
            ).toList(),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.grey[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'No hay recomendaciones disponibles',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
