import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

import '../services/rentas_service.dart';
import '../features/explore/explore_controller.dart';

/// Widget para mostrar rentas en el mapa
class RentasWidget extends StatefulWidget {
  const RentasWidget({super.key});

  @override
  State<RentasWidget> createState() => _RentasWidgetState();
}

class _RentasWidgetState extends State<RentasWidget> {
  final RentasService _rentasService = RentasService();
  bool _isLoading = false;
  bool _showRentas = false;
  List<RentaData> _rentas = [];
  final List<MarkerId> _addedMarkerIds = [];

  @override
  void dispose() {
    _rentasService.close();
    super.dispose();
  }

  Future<void> _toggleRentas() async {
    final controller = context.read<ExploreController>();

    if (_showRentas) {
      // Ocultar rentas
      _removeRentasMarkers(controller);
      setState(() {
        _showRentas = false;
      });
    } else {
      // Mostrar rentas
      setState(() {
        _isLoading = true;
      });

      try {
        print('🔄 Iniciando carga de rentas...');
        final rentas = await _rentasService.getAllRentas();
        print('📦 Rentas recibidas del servicio: ${rentas.length}');
        
        if (rentas.isEmpty) {
          print('⚠️ No se obtuvieron rentas del servicio');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('⚠️ No se encontraron propiedades en renta'),
                duration: Duration(seconds: 2),
                backgroundColor: Colors.orange,
              ),
            );
          }
          setState(() {
            _isLoading = false;
          });
          return;
        }
        
        print('📍 Agregando marcadores al mapa...');
        _addRentasMarkers(controller, rentas);
        
        setState(() {
          _rentas = rentas;
          _showRentas = true;
          _isLoading = false;
        });

        print('✅ Estado actualizado: ${_rentas.length} rentas, _showRentas=$_showRentas');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ${rentas.length} propiedades en renta mostradas'),
              duration: const Duration(seconds: 2),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Error cargando rentas: $e'),
              duration: const Duration(seconds: 3),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _addRentasMarkers(ExploreController controller, List<RentaData> rentas) {
    print('📍 Agregando ${rentas.length} marcadores de rentas al mapa...');
    
    // Limpiar marcadores anteriores si existen
    for (final markerId in _addedMarkerIds) {
      controller.removeMarker(markerId);
    }
    _addedMarkerIds.clear();

    for (final renta in rentas) {
      try {
        final markerId = MarkerId('renta_${renta.id}');
        
        print('   🎯 Creando marcador para renta ${renta.id}: ${renta.nombre} en (${renta.latitude}, ${renta.longitude})');
        
        final marker = Marker(
          markerId: markerId,
          position: LatLng(renta.latitude, renta.longitude),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          infoWindow: InfoWindow(
            title: renta.nombre ?? 'Propiedad en Renta',
            snippet: _buildInfoWindowSnippet(renta),
          ),
          onTap: () {
            // Mostrar información detallada en un modal
            _showRentaDetailModal(context, renta);
          },
        );

        controller.addMarker(markerId, marker);
        _addedMarkerIds.add(markerId);
        print('   ✅ Marcador agregado: $markerId');
      } catch (e) {
        print('   ❌ Error creando marcador para renta ${renta.id}: $e');
      }
    }

    print('✅ Total de ${_addedMarkerIds.length} marcadores agregados al mapa');
  }

  void _removeRentasMarkers(ExploreController controller) {
    for (final markerId in _addedMarkerIds) {
      controller.removeMarker(markerId);
    }
    _addedMarkerIds.clear();
  }

  String _buildInfoWindowSnippet(RentaData renta) {
    final parts = <String>[];
    final data = renta.data;
    
    // Orden de prioridad para mostrar en el tooltip
    // 1. Tipo de propiedad
    if (renta.tipoVivienda != null && renta.tipoVivienda!.isNotEmpty) {
      parts.add(renta.tipoVivienda!);
    }
    
    // 2. Superficie
    if (renta.superficieM2 != null) {
      parts.add('${renta.superficieM2!.toStringAsFixed(0)} m²');
    }
    
    // 3. Cuartos
    if (renta.numCuartos != null) {
      parts.add('${renta.numCuartos} hab.');
    }
    
    // 4. Baños
    if (renta.numBanos != null) {
      parts.add('${renta.numBanos} baños');
    }
    
    // 5. Precio (si existe)
    final precio = data['precio'] ?? data['renta'] ?? data['costo'];
    if (precio != null) {
      final precioStr = precio is num 
          ? '\$${precio.toStringAsFixed(0)}' 
          : precio.toString();
      parts.add(precioStr);
    }
    
    // 6. Indicador de fotos
    if (renta.fotos.isNotEmpty) {
      parts.add('📷 ${renta.fotos.length} foto${renta.fotos.length > 1 ? 's' : ''}');
    }

    return parts.isNotEmpty ? parts.join(' • ') : 'Ver detalles';
  }

  void _showRentaDetailModal(BuildContext context, RentaData renta) {
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
                            renta.nombre ?? 'Propiedad en Renta',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (renta.tipoVivienda != null)
                            Text(
                              renta.tipoVivienda!,
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
                if (renta.fotos.isNotEmpty) ...[
                  _buildFotosSection(renta.fotos),
                  const SizedBox(height: 24),
                ],
                
                // Información principal
                if (renta.descripcion != null && renta.descripcion!.isNotEmpty) ...[
                  _buildInfoSection('Descripción', renta.descripcion!),
                  const SizedBox(height: 16),
                ],

                // Características principales
                _buildInfoSection('Características', ''),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    if (renta.superficieM2 != null)
                      _buildFeatureChip(
                        Icons.square_foot,
                        '${renta.superficieM2!.toStringAsFixed(0)} m²',
                      ),
                    if (renta.numCuartos != null)
                      _buildFeatureChip(
                        Icons.bed,
                        '${renta.numCuartos} hab.',
                      ),
                    if (renta.numBanos != null)
                      _buildFeatureChip(
                        Icons.bathroom,
                        '${renta.numBanos} baños',
                      ),
                    if (renta.numCajones != null)
                      _buildFeatureChip(
                        Icons.local_parking,
                        '${renta.numCajones} cajones',
                      ),
                  ],
                ),
                
                // Mostrar todos los datos adicionales de la tabla
                _buildAllDataSection(renta),

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

  Widget _buildAllDataSection(RentaData renta) {
    final data = renta.data;
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
    // Convertir snake_case o camelCase a formato legible
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

  @override
  Widget build(BuildContext context) {
    return Consumer<ExploreController>(
      builder: (context, controller, child) {
        // Posición: arriba del botón de Capas GIS (80)
        // Análisis está en bottom: 18
        // Capas GIS está en bottom: 80
        // Rentas debe estar en bottom: 140 (arriba de Capas GIS)
        // Siempre mostrar arriba del botón de Capas GIS
        const bottomPosition = 140.0;

        return Positioned(
          left: 12,
          bottom: bottomPosition,
          child: FloatingActionButton.extended(
            onPressed: _isLoading ? null : _toggleRentas,
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Icon(_showRentas ? Icons.visibility_off : Icons.home),
            label: Text(_showRentas ? 'Ocultar Rentas' : 'Rentas'),
            backgroundColor: _showRentas ? Colors.red : Colors.purple,
            foregroundColor: Colors.white,
          ),
        );
      },
    );
  }
}

