import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/delitos_service.dart';
import '../models/delito_model.dart';

class CrimeLayerWidget extends StatefulWidget {
  final Function(List<DelitoModel>) onDelitosLoaded;
  final double? latitude;
  final double? longitude;

  const CrimeLayerWidget({
    super.key,
    required this.onDelitosLoaded,
    this.latitude,
    this.longitude,
  });

  @override
  State<CrimeLayerWidget> createState() => _CrimeLayerWidgetState();
}

class _CrimeLayerWidgetState extends State<CrimeLayerWidget> {
  final DelitosService _delitosService = DelitosService();
  List<DelitoModel> _delitos = [];
  bool _isLoading = false;
  bool _isVisible = false;
  String _selectedFilter = 'Todos';
  double _radiusKm = 1.0;

  final List<String> _filterOptions = [
    'Todos',
    'Homicidio doloso',
    'Robo a casa habitación',
    'Robo a negocio',
    'Robo a persona',
    'Robo de vehículo',
    'Violencia familiar',
  ];

  @override
  void initState() {
    super.initState();
    _loadDelitos();
  }

  Future<void> _loadDelitos() async {
    setState(() => _isLoading = true);
    
    try {
      await _delitosService.loadDelitosFromCsv();
      _delitos = _delitosService.delitos;
      
      if (widget.latitude != null && widget.longitude != null) {
        _filterDelitosByLocation();
      }
      
      widget.onDelitosLoaded(_delitos);
    } catch (e) {
      print('Error cargando delitos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filterDelitosByLocation() {
    if (widget.latitude != null && widget.longitude != null) {
      _delitos = _delitosService.getDelitosByLocation(
        latitude: widget.latitude!,
        longitude: widget.longitude!,
        radiusMeters: _radiusKm * 1000,
      );
      
      if (_selectedFilter != 'Todos') {
        _delitos = _delitos.where((delito) => 
          delito.delito.toLowerCase().contains(_selectedFilter.toLowerCase())
        ).toList();
      }
      
      widget.onDelitosLoaded(_delitos);
    }
  }

  void _toggleVisibility() {
    setState(() => _isVisible = !_isVisible);
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _filterDelitosByLocation();
  }

  void _onRadiusChanged(double radius) {
    setState(() => _radiusKm = radius);
    _filterDelitosByLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Capa de Delitos',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              Switch(
                value: _isVisible,
                onChanged: (value) => _toggleVisibility(),
                activeColor: Colors.red[700],
              ),
            ],
          ),
          
          if (_isVisible) ...[
            const SizedBox(height: 16),
            
            // Filtro por tipo de delito
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tipo de Delito:',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: _selectedFilter,
                    isExpanded: true,
                    onChanged: (value) => value != null ? _onFilterChanged(value) : null,
                    items: _filterOptions.map((filter) {
                      return DropdownMenuItem<String>(
                        value: filter,
                        child: Text(
                          filter,
                          style: GoogleFonts.poppins(fontSize: 12),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Control de radio
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Radio de búsqueda: ${_radiusKm.toStringAsFixed(1)} km',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: _radiusKm,
                    min: 0.5,
                    max: 10.0,
                    divisions: 19,
                    onChanged: _onRadiusChanged,
                    activeColor: Colors.red[700],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Estadísticas
            if (_isLoading)
              const CircularProgressIndicator()
            else
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estadísticas:',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.red[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• ${_delitos.length} delitos encontrados',
                      style: GoogleFonts.poppins(fontSize: 12),
                    ),
                    if (_delitos.isNotEmpty) ...[
                      Text(
                        '• Último delito: ${_delitos.first.fecha}',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                      Text(
                        '• Municipio más afectado: ${_getMostAffectedMunicipio()}',
                        style: GoogleFonts.poppins(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Botón para subir a Firestore (solo para desarrollo)
            if (_delitos.isNotEmpty)
              ElevatedButton.icon(
                onPressed: () async {
                  await _delitosService.uploadDelitosToFirestore();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Delitos subidos a Firestore'),
                      backgroundColor: Colors.green,
                    ),
                  );
                },
                icon: const Icon(Icons.cloud_upload),
                label: const Text('Subir a Firestore'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ],
      ),
    );
  }

  String _getMostAffectedMunicipio() {
    if (_delitos.isEmpty) return 'N/A';
    
    final Map<String, int> counts = {};
    for (final delito in _delitos) {
      counts[delito.municipio] = (counts[delito.municipio] ?? 0) + 1;
    }
    
    return counts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }
}
