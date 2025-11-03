import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/postgres_gis_service.dart';
import '../models/estacion_transporte.dart';
import '../models/ruta_transporte.dart';
import '../models/linea_transporte.dart';
import 'transporte_detail_modal.dart';

class TransporteWidget extends StatefulWidget {
  final double latitude;
  final double longitude;

  const TransporteWidget({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<TransporteWidget> createState() => _TransporteWidgetState();
}

class _TransporteWidgetState extends State<TransporteWidget> {
  final PostgresGisService _gisService = PostgresGisService();
  List<EstacionTransporte> _estaciones = [];
  List<RutaTransporte> _rutas = [];
  List<LineaTransporte> _lineas = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTransporte();
  }

  Future<void> _loadTransporte() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Cargar todas las capas de transporte
      final [estacionesData, rutasData, lineasData] = await Future.wait([
        _gisService.getEstacionesTransporte(),
        _gisService.getRutasTransporte(),
        _gisService.getLineasTransporte(),
      ]);

      setState(() {
        _estaciones = estacionesData.map((d) => EstacionTransporte.fromJson(d)).toList();
        _rutas = rutasData.map((d) => RutaTransporte.fromJson(d)).toList();
        _lineas = lineasData.map((d) => LineaTransporte.fromJson(d)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error cargando datos de transporte: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: Colors.purple[600],
        ),
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
                colors: [
                  Colors.purple[700]!,
                  Colors.purple[600]!,
                ],
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
                  child: const Icon(
                    Icons.directions_bus,
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
                        'Red de Transporte',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_estaciones.length} estaciones • ${_rutas.length} rutas • ${_lineas.length} líneas',
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

          // Estaciones
          _buildSection(
            'Estaciones de Transporte',
            Icons.train,
            _estaciones.length,
            Colors.blue,
            _estaciones.map((e) => _EstacionItem(estacion: e)).toList(),
          ),
          const SizedBox(height: 16),

          // Rutas
          _buildSection(
            'Rutas de Transporte',
            Icons.route,
            _rutas.length,
            Colors.orange,
            _rutas.map((r) => _RutaItem(ruta: r)).toList(),
          ),
          const SizedBox(height: 16),

          // Líneas
          _buildSection(
            'Líneas de Transporte',
            Icons.timeline,
            _lineas.length,
            Colors.purple,
            _lineas.map((l) => _LineaItem(linea: l)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, int count, Color color, List<Widget> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.poppins(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }
}

// Helper widgets
class _EstacionItem extends StatelessWidget {
  final EstacionTransporte estacion;

  const _EstacionItem({required this.estacion});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetailModal(context, estacion),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.train, color: Colors.blue[700], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estacion.nombre ?? 'Sin nombre',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (estacion.sistema != null)
                      Text(
                        estacion.sistema!,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              if (estacion.estado != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: estacion.estado == 'Existente' 
                        ? Colors.green[100] 
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    estacion.estado!,
                    style: GoogleFonts.poppins(
                      color: estacion.estado == 'Existente'
                          ? Colors.green[700]
                          : Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDetailModal(BuildContext context, EstacionTransporte estacion) {
    final data = <String, String?>{
      'Nombre': estacion.nombre,
      'Sistema': estacion.sistema,
      'Estructura': estacion.estructura,
      'Estado': estacion.estado,
      'Línea': estacion.linea,
    };
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransporteDetailModal(
        title: 'Detalles de Estación',
        data: data,
      ),
    );
  }
}

class _RutaItem extends StatelessWidget {
  final RutaTransporte ruta;

  const _RutaItem({required this.ruta});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetailModal(context, ruta),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.route, color: Colors.orange[700], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ruta.name ?? 'Sin nombre',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (ruta.folderPath != null)
                      Text(
                        ruta.folderPath!,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDetailModal(BuildContext context, RutaTransporte ruta) {
    final data = <String, String?>{
      'Nombre': ruta.name,
      'Ruta': ruta.folderPath,
    };
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransporteDetailModal(
        title: 'Detalles de Ruta',
        data: data,
      ),
    );
  }
}

class _LineaItem extends StatelessWidget {
  final LineaTransporte linea;

  const _LineaItem({required this.linea});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetailModal(context, linea),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.purple[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.route, color: Colors.purple[700], size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      linea.nombre ?? 'Sin nombre',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (linea.tipo != null)
                      Text(
                        linea.tipo!,
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              if (linea.estado != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: linea.estado == 'Existente' 
                        ? Colors.green[100] 
                        : Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    linea.estado!,
                    style: GoogleFonts.poppins(
                      color: linea.estado == 'Existente'
                          ? Colors.green[700]
                          : Colors.orange[700],
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showDetailModal(BuildContext context, LineaTransporte linea) {
    final data = <String, String?>{
      'Nombre': linea.nombre,
      'Tipo de Corredor': linea.tipoCo,
      'Tipo': linea.tipo,
      'Estado': linea.estado,
    };
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TransporteDetailModal(
        title: 'Detalles de Línea',
        data: data,
      ),
    );
  }
}

