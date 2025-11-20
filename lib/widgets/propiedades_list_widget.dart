import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/rentas_service.dart';
import 'rentas_widget.dart';

/// Widget para mostrar lista de propiedades en el análisis integrado
class PropiedadesListWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const PropiedadesListWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<PropiedadesListWidget> createState() => _PropiedadesListWidgetState();
}

class _PropiedadesListWidgetState extends State<PropiedadesListWidget> {
  final RentasService _rentasService = RentasService();
  List<RentaData> _propiedades = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPropiedades();
  }

  @override
  void dispose() {
    _rentasService.close();
    super.dispose();
  }

  Future<void> _loadPropiedades() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      print('🔄 PropiedadesListWidget: Cargando propiedades...');
      final propiedades = await _rentasService.getAllRentas();
      print('✅ PropiedadesListWidget: ${propiedades.length} propiedades cargadas');
      setState(() {
        _propiedades = propiedades;
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ PropiedadesListWidget: Error cargando propiedades: $e');
      print('📚 Stack trace: $stackTrace');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(
              'Error cargando propiedades',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error!,
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPropiedades,
              child: const Text('Reintentar'),
            ),
          ],
        ),
      );
    }

    if (_propiedades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.home_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No hay propiedades disponibles',
              style: GoogleFonts.poppins(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPropiedades,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _propiedades.length,
        itemBuilder: (context, index) {
          final propiedad = _propiedades[index];
          return _buildPropiedadCard(propiedad);
        },
      ),
    );
  }

  Widget _buildPropiedadCard(RentaData propiedad) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showPropiedadModal(propiedad),
        borderRadius: BorderRadius.circular(12),
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
                      color: Colors.purple[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.home,
                      color: Colors.purple[700],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          propiedad.nombre ?? 'Propiedad',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (propiedad.tipoVivienda != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            propiedad.tipoVivienda!,
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  if (propiedad.superficieM2 != null)
                    _buildInfoChip(
                      Icons.square_foot,
                      '${propiedad.superficieM2!.toStringAsFixed(0)} m²',
                    ),
                  if (propiedad.numCuartos != null)
                    _buildInfoChip(
                      Icons.bed,
                      '${propiedad.numCuartos} hab.',
                    ),
                  if (propiedad.numBanos != null)
                    _buildInfoChip(
                      Icons.bathroom,
                      '${propiedad.numBanos} baños',
                    ),
                  if (propiedad.numCajones != null)
                    _buildInfoChip(
                      Icons.local_parking,
                      '${propiedad.numCajones} cajones',
                    ),
                  if (propiedad.fotos.isNotEmpty)
                    _buildInfoChip(
                      Icons.photo,
                      '${propiedad.fotos.length} foto${propiedad.fotos.length > 1 ? 's' : ''}',
                    ),
                ],
              ),
              if (propiedad.descripcion != null && propiedad.descripcion!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  propiedad.descripcion!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.purple[700]),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12,
            color: Colors.grey[700],
          ),
        ),
      ],
    );
  }

  void _showPropiedadModal(RentaData propiedad) {
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
                        color: Colors.purple[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.home, color: Colors.purple[700], size: 32),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            propiedad.nombre ?? 'Propiedad',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (propiedad.tipoVivienda != null)
                            Text(
                              propiedad.tipoVivienda!,
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
                const SizedBox(height: 24),
                
                // Galería de fotos
                if (propiedad.fotos.isNotEmpty) ...[
                  _buildFotosSection(propiedad.fotos),
                  const SizedBox(height: 24),
                ],
                
                if (propiedad.descripcion != null && propiedad.descripcion!.isNotEmpty) ...[
                  _buildInfoSection('Descripción', propiedad.descripcion!),
                  const SizedBox(height: 16),
                ],
                _buildInfoSection('Características', ''),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (propiedad.superficieM2 != null)
                      _buildFeatureChip(Icons.square_foot, '${propiedad.superficieM2!.toStringAsFixed(0)} m²'),
                    if (propiedad.numCuartos != null)
                      _buildFeatureChip(Icons.bed, '${propiedad.numCuartos} hab.'),
                    if (propiedad.numBanos != null)
                      _buildFeatureChip(Icons.bathroom, '${propiedad.numBanos} baños'),
                    if (propiedad.numCajones != null)
                      _buildFeatureChip(Icons.local_parking, '${propiedad.numCajones} cajones'),
                  ],
                ),
                _buildAllDataSection(propiedad),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (content.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            content,
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFeatureChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.purple[700]),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.purple[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllDataSection(RentaData propiedad) {
    final data = propiedad.data;
    final excludedKeys = {
      'latitude', 'longitude', 'geom_json', 'id', 'gid', 'iddato',
      'nombre', 'descripcion', 'tipo_vivienda', 'tipo', 'titulo', 'detalles',
      'superficie_m2', 'superficie', 'm2',
      'num_cuartos', 'cuartos', 'habitaciones',
      'num_banos', 'num_ba¤os', 'banos',
      'num_cajones', 'cajones', 'estacionamiento',
      'extras', 'caracteristicas',
      'codigopostal', 'cp', 'codigo_postal',
      'fotos', 'foto', 'imagenes', 'imagen', // Excluir fotos de información adicional
    };
    
    final additionalData = <MapEntry<String, dynamic>>[];
    for (final entry in data.entries) {
      if (!excludedKeys.contains(entry.key.toLowerCase()) && 
          entry.value != null && 
          entry.value.toString().isNotEmpty) {
        additionalData.add(entry);
      }
    }
    
    if (additionalData.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        _buildInfoSection('Información Adicional', ''),
        const SizedBox(height: 12),
        ...additionalData.map((entry) {
          final key = _formatKey(entry.key);
          final value = _formatValue(entry.value);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 120,
                  child: Text(
                    key,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey[700],
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    value,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  String _formatKey(String key) {
    return key
        .replaceAll('_', ' ')
        .replaceAllMapped(RegExp(r'([A-Z])'), (match) => ' ${match.group(1)}')
        .split(' ')
        .map((word) => word.isEmpty 
            ? '' 
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ')
        .trim();
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is num) {
      if (value % 1 == 0) {
        return value.toInt().toString();
      } else {
        return value.toStringAsFixed(2);
      }
    }
    return value.toString();
  }

  Widget _buildFotosSection(List<String> fotos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.photo_library, color: Colors.purple[700], size: 20),
            const SizedBox(width: 8),
            Text(
              'Fotos (${fotos.length})',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: fotos.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.only(right: index < fotos.length - 1 ? 12 : 0),
                width: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    fotos[index],
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.image_not_supported, 
                                 size: 40, 
                                 color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Error cargando imagen',
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

