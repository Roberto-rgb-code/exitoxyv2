import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../services/visor_urbano_service.dart';
import 'glossary_tooltip.dart';

class VisorUrbanoWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const VisorUrbanoWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<VisorUrbanoWidget> createState() => _VisorUrbanoWidgetState();
}

class _VisorUrbanoWidgetState extends State<VisorUrbanoWidget> {
  Map<String, dynamic>? _predioData;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPredioData();
  }

  Future<void> _loadPredioData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      final rawData = await VisorUrbanoService.searchPredioByCoordinates(
        widget.latitude,
        widget.longitude,
      );
      
      final processedData = VisorUrbanoService.processPredioData(rawData);
      
      if (mounted) {
        setState(() {
          _predioData = processedData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error cargando datos del predio: $e';
        });
      }
      print('Error cargando predio: $e');
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
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green[700]!,
                  Colors.green[600]!,
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
                    Icons.home_work,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Datos del ',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          GestureDetector(
                            onTap: () => showGlossaryModal(context, 'predio'),
                            child: Row(
                              children: [
                                Text(
                                  'Predio',
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                GlossaryHelpIcon(
                                  termKey: 'predio',
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
                            'Visor Urbano',
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GlossaryHelpIcon(
                            termKey: 'visor_urbano',
                            color: Colors.white60,
                            size: 12,
                          ),
                        ],
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

          // Contenido
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorState(_errorMessage!, colorScheme)
                    : _predioData == null || _predioData!['success'] == false
                        ? _buildEmptyState(colorScheme)
                        : _buildPredioContent(_predioData!, colorScheme),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildErrorState(String error, ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Error',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.red[600],
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              error,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _loadPredioData,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.home_outlined,
            size: 64,
            color: colorScheme.onSurface.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No se encontró información',
            style: GoogleFonts.poppins(
              fontSize: 16,
              color: colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'del predio en esta ubicación',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPredioContent(Map<String, dynamic> data, ColorScheme colorScheme) {
    final predio = data['predio'] ?? {};
    final ubicacion = data['ubicacion'] ?? {};
    final construccion = data['construccion'] ?? {};
    final uso = data['uso'] ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información básica
          _buildSection(
            'Información Básica',
            Icons.info,
            [
              _buildInfoItem('Clave', predio['clave'] ?? 'N/A', colorScheme),
              _buildInfoItem('Superficie Terreno', '${predio['superficie_terreno'] ?? 0} m²', colorScheme),
              _buildInfoItem('Superficie Construcción', '${predio['superficie_construccion'] ?? 0} m²', colorScheme),
              _buildInfoItem('Valor Total', '\$${predio['valor_total']?.toStringAsFixed(0) ?? '0'}', colorScheme),
            ],
            colorScheme,
          ),

          const SizedBox(height: 16),

          // Ubicación
          _buildSection(
            'Ubicación',
            Icons.location_on,
            [
              _buildInfoItem('Calle', ubicacion['calle'] ?? 'N/A', colorScheme),
              _buildInfoItem('Número', ubicacion['numero_exterior'] ?? 'N/A', colorScheme),
              _buildInfoItem('Colonia', ubicacion['colonia'] ?? 'N/A', colorScheme),
              _buildInfoItem('Código Postal', ubicacion['codigo_postal'] ?? 'N/A', colorScheme),
              _buildInfoItem('Municipio', ubicacion['municipio'] ?? 'N/A', colorScheme),
              _buildInfoItem('Estado', ubicacion['estado'] ?? 'N/A', colorScheme),
            ],
            colorScheme,
          ),

          const SizedBox(height: 16),

          // Construcción
          _buildSection(
            'Construcción',
            Icons.home,
            [
              _buildInfoItem('Tipo', construccion['tipo'] ?? 'N/A', colorScheme),
              _buildInfoItem('Antigüedad', '${construccion['antiguedad'] ?? 0} años', colorScheme),
              _buildInfoItem('Pisos', '${construccion['pisos'] ?? 1}', colorScheme),
              _buildInfoItem('Habitaciones', '${construccion['habitaciones'] ?? 0}', colorScheme),
              _buildInfoItem('Baños', '${construccion['banos'] ?? 0}', colorScheme),
            ],
            colorScheme,
          ),

          const SizedBox(height: 16),

          // Uso del suelo
          _buildSectionWithGlossary(
            context,
            'Uso del Suelo',
            Icons.landscape,
            'uso_suelo',
            [
              _buildInfoItem('Código', uso['codigo'] ?? 'N/A', colorScheme),
              _buildInfoItem('Descripción', uso['descripcion'] ?? 'N/A', colorScheme),
              _buildInfoItem('Intensidad', uso['intensidad'] ?? 'N/A', colorScheme),
            ],
            colorScheme,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, List<Widget> children, ColorScheme colorScheme) {
    return Container(
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
              Icon(icon, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSectionWithGlossary(BuildContext context, String title, IconData icon, String glossaryKey, List<Widget> children, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => showGlossaryModal(context, glossaryKey),
            child: Row(
              children: [
                Icon(icon, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                GlossaryHelpIcon(
                  termKey: glossaryKey,
                  color: colorScheme.primary,
                  size: 16,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoItem(String label, String value, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: colorScheme.onSurface.withOpacity(0.8),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 14,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
