import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../services/denue_service.dart';
import '../services/denue_repository.dart';
import 'denue_detail_modal.dart';

class DenueBusinessesWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String businessType;

  const DenueBusinessesWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.businessType = 'Restaurantes',
  });

  @override
  State<DenueBusinessesWidget> createState() => _DenueBusinessesWidgetState();
}

class _DenueBusinessesWidgetState extends State<DenueBusinessesWidget> {
  List<Map<String, dynamic>> _businesses = [];
  bool _isLoading = false;
  String _selectedType = 'Restaurantes';

  @override
  void initState() {
    super.initState();
    _selectedType = widget.businessType;
    _loadBusinesses();
  }

  Future<void> _loadBusinesses() async {
    setState(() => _isLoading = true);
    
    try {
      final businesses = await DenueService.fetchBusinesses(
        _selectedType,
        widget.latitude,
        widget.longitude,
      );
      
      setState(() {
        _businesses = businesses;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error cargando negocios DENUE: $e');
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
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
                    Icons.business,
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
                        'Negocios DENUE',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_businesses.length} negocios encontrados',
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
          ),

          // Filtro de tipo de negocio
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tipo de negocio:',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant.withOpacity(0.3),
                  ),
                  items: DenueService.getPopularBusinessTypes().map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedType = value);
                      _loadBusinesses();
                    }
                  },
                ),
              ],
            ),
          ),

          // Lista de negocios
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _businesses.isEmpty
                    ? _buildEmptyState(colorScheme)
                    : ListView.builder(
                        itemCount: _businesses.length,
                        itemBuilder: (context, index) {
                          final business = _businesses[index];
                          return _buildBusinessCard(business, colorScheme);
                        },
                      ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.business_outlined,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontraron negocios',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'del tipo "$_selectedType"',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessCard(Map<String, dynamic> business, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => _showDenueModal(context, business),
      child: Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.business,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      business['nombre'] ?? 'Negocio',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      business['descripcion'] ?? 'Sin descripción',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Información adicional
          if (business['telefono'] != null && business['telefono'].toString().isNotEmpty) ...[
            _buildInfoRow(Icons.phone, 'Teléfono', business['telefono'].toString(), colorScheme),
            const SizedBox(height: 8),
          ],
          
          if (business['correo'] != null && business['correo'].toString().isNotEmpty) ...[
            _buildInfoRow(Icons.email, 'Email', business['correo'].toString(), colorScheme),
            const SizedBox(height: 8),
          ],
          
          // Construir dirección
          if (business['nombre_vialidad'] != null || business['numero_exterior'] != null || business['asentamiento'] != null) ...[
            _buildInfoRow(
              Icons.location_on,
              'Dirección',
              _buildAddress(business),
              colorScheme,
            ),
            const SizedBox(height: 8),
          ],
          
          // Ubicación (municipio y estado)
          if (business['municipio'] != null || business['estado'] != null) ...[
            _buildInfoRow(
              Icons.location_city,
              'Ubicación',
              '${business['municipio'] ?? ''}${business['municipio'] != null && business['estado'] != null ? ', ' : ''}${business['estado'] ?? ''}',
              colorScheme,
            ),
          ],
        ],
      ),
    ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, ColorScheme colorScheme) {
    return Row(
      children: [
        Icon(icon, size: 16, color: colorScheme.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '$label: $value',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: colorScheme.onSurface.withOpacity(0.8),
            ),
          ),
        ),
      ],
    );
  }

  String _buildAddress(Map<String, dynamic> business) {
    final parts = <String>[];
    if (business['tipo_vialidad'] != null && business['tipo_vialidad'].toString().isNotEmpty) {
      parts.add(business['tipo_vialidad'].toString());
    }
    if (business['nombre_vialidad'] != null && business['nombre_vialidad'].toString().isNotEmpty) {
      parts.add(business['nombre_vialidad'].toString());
    }
    if (business['numero_exterior'] != null && business['numero_exterior'].toString().isNotEmpty) {
      parts.add('No. ${business['numero_exterior']}');
    }
    if (business['numero_interior'] != null && business['numero_interior'].toString().isNotEmpty) {
      parts.add('Int. ${business['numero_interior']}');
    }
    if (business['asentamiento'] != null && business['asentamiento'].toString().isNotEmpty) {
      parts.add(business['asentamiento'].toString());
    }
    return parts.isEmpty ? 'Dirección no disponible' : parts.join(', ');
  }

  void _showDenueModal(BuildContext context, Map<String, dynamic> business) {
    // Construir dirección completa
    final direccion = _buildAddress(business);
    
    // Convertir el Map a MarketEntry
    final entry = MarketEntry(
      name: business['nombre']?.toString() ?? 'Negocio',
      firm: business['nombre']?.toString() ?? 'Empresa',
      activity: business['descripcion']?.toString() ?? 'Sin descripción',
      position: LatLng(
        double.tryParse(business['lat']?.toString() ?? business['latitud']?.toString() ?? '0') ?? 0.0,
        double.tryParse(business['lon']?.toString() ?? business['longitud']?.toString() ?? '0') ?? 0.0,
      ),
      postalCode: business['codigo_postal']?.toString(),
      description: business['descripcion']?.toString(),
      direccion: direccion != 'Dirección no disponible' ? direccion : null,
      municipio: business['municipio']?.toString(),
      estado: business['estado']?.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DenueDetailModal(entry: entry),
    );
  }
}
