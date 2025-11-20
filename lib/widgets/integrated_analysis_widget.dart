import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/delitos_service.dart';
import '../services/recommendation_service.dart';
import '../services/facebook_marketplace_service.dart';
import '../services/denue_service.dart';
import '../services/visor_urbano_service.dart';
import 'crime_layer_widget.dart';
import 'recommendation_display_widget.dart';
import 'marketplace_listings_widget.dart';
import 'map3d_widget.dart';
import 'denue_businesses_widget.dart';
import 'visor_urbano_widget.dart';
import 'recommendations_button.dart';
import 'propiedades_list_widget.dart';

class IntegratedAnalysisWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;

  const IntegratedAnalysisWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  @override
  State<IntegratedAnalysisWidget> createState() => _IntegratedAnalysisWidgetState();
}

class _IntegratedAnalysisWidgetState extends State<IntegratedAnalysisWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DelitosService _delitosService = DelitosService();
  final RecommendationService _recommendationService = RecommendationService();
  final FacebookMarketplaceService _marketplaceService = FacebookMarketplaceService();
  
  List<dynamic> _recommendations = [];
  List<dynamic> _marketplaceListings = [];
  List<Map<String, dynamic>> _denueBusinesses = [];
  Map<String, dynamic>? _visorUrbanoData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    
    try {
      // Cargar delitos
      await _delitosService.loadDelitosFromCsv();
      
      // Generar recomendaciones
      _recommendations = await _recommendationService.generateRecommendations(
        latitude: widget.latitude,
        longitude: widget.longitude,
        locationName: widget.locationName,
      );
      
      // Cargar propiedades de marketplace
      _marketplaceListings = await _marketplaceService.searchMarketplaceListings(
        latitude: widget.latitude,
        longitude: widget.longitude,
        radius: 3000,
        limit: 20,
      );
      
      // Cargar negocios DENUE
      _denueBusinesses = await DenueService.fetchBusinesses(
        'Restaurantes',
        widget.latitude,
        widget.longitude,
      );
      
      // Cargar datos de Visor Urbano
      try {
        final rawData = await VisorUrbanoService.searchPredioByCoordinates(
          widget.latitude,
          widget.longitude,
        );
        _visorUrbanoData = VisorUrbanoService.processPredioData(rawData);
      } catch (e) {
        print('Error cargando Visor Urbano: $e');
        _visorUrbanoData = {
          'success': false,
          'message': 'Error conectando con Visor Urbano: $e'
        };
      }
      
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error cargando datos integrados: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      margin: const EdgeInsets.all(16),
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
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colorScheme.primary,
                  colorScheme.secondary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
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
                        Icons.analytics,
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
                            'Análisis Integrado',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            widget.locationName,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (_isLoading)
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white.withOpacity(0.7),
                  labelStyle: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(icon: Icon(Icons.warning), text: 'Delitos'),
                    Tab(icon: Icon(Icons.business), text: 'DENUE'),
                    Tab(icon: Icon(Icons.home_work), text: 'Visor Urbano'),
                    Tab(icon: Icon(Icons.home), text: 'Rentas'),
                    Tab(icon: Icon(Icons.recommend), text: 'Recomendaciones'),
                    Tab(icon: Icon(Icons.storefront), text: 'Marketplace'),
                    Tab(icon: Icon(Icons.threed_rotation), text: 'Mapa 3D'),
                  ],
                ),
              ],
            ),
          ),
          
          // Contenido de las pestañas
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Pestaña de Delitos
                _buildDelitosContent(colorScheme),
                
                // Pestaña de DENUE
                DenueBusinessesWidget(
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                ),
                
                // Pestaña de Visor Urbano
                VisorUrbanoWidget(
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                ),
                
                // Pestaña de Rentas
                PropiedadesListWidget(
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                ),
                
                // Pestaña de Recomendaciones
                Column(
                  children: [
                    RecommendationsButton(
                      onPressed: () async {
                        setState(() => _isLoading = true);
                        _recommendations = await _recommendationService.generateRecommendations(
                          latitude: widget.latitude,
                          longitude: widget.longitude,
                          locationName: widget.locationName,
                        );
                        setState(() => _isLoading = false);
                      },
                      isLoading: _isLoading,
                      recommendationCount: _recommendations.length,
                    ),
                    Expanded(
                      child: _recommendations.isEmpty
                          ? _buildEmptyState(
                              'No hay recomendaciones disponibles',
                              Icons.recommend,
                              colorScheme,
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: _recommendations.map((recommendation) {
                                  return RecommendationDisplayWidget(
                                    recommendation: recommendation,
                                  );
                                }).toList(),
                              ),
                            ),
                    ),
                  ],
                ),
                
                // Pestaña de Marketplace
                _marketplaceListings.isEmpty
                    ? _buildEmptyState(
                        'No hay propiedades disponibles',
                        Icons.storefront,
                        colorScheme,
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: _marketplaceListings.map((listing) {
                            return _buildMarketplaceCard(listing, colorScheme);
                          }).toList(),
                        ),
                      ),
                
                // Pestaña de Mapa 3D
                Map3DWidget(
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                  locationName: widget.locationName,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, IconData icon, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMarketplaceCard(dynamic listing, ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: colorScheme.surfaceVariant,
            ),
            child: const Icon(Icons.home_work),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  listing.name ?? 'Propiedad',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (listing.priceRange != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '\$${listing.priceRange.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDelitosContent(ColorScheme colorScheme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Header
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
                    const SizedBox(width: 12),
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
                            'Datos del IIEG - Zona Metropolitana de Guadalajara',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _isLoading ? null : () async {
                    setState(() => _isLoading = true);
                    try {
                      await _delitosService.loadDelitosFromCsv();
                      final delitos = _delitosService.getDelitosByLocation(
                        latitude: widget.latitude,
                        longitude: widget.longitude,
                        radiusMeters: 2000,
                      );
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Se encontraron ${delitos.length} delitos en el área'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      setState(() => _isLoading = false);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error cargando delitos: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  icon: _isLoading 
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.refresh),
                  label: Text(_isLoading ? 'Cargando...' : 'Cargar Delitos'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Información sobre los datos
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceVariant.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, color: colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Información',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '• Los datos provienen del Instituto de Información Estadística y Geográfica (IIEG)',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Incluye delitos reportados en la Zona Metropolitana de Guadalajara',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• Los datos se filtran por radio de 2km desde la ubicación seleccionada',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: colorScheme.onSurface.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
