import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;


class Map3DWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locationName;

  const Map3DWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locationName,
  });

  @override
  State<Map3DWidget> createState() => _Map3DWidgetState();
}

class _Map3DWidgetState extends State<Map3DWidget> with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _show3D = false;
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  
  double _zoom = 1.0;
  double _rotationX = 0.0;
  double _rotationY = 0.0;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    )..repeat();
    
    _scaleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    
    _loadData();
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      // Simular carga de datos (sin delitos)
      await Future.delayed(const Duration(milliseconds: 500));
      print('📍 Mapa 3D cargado sin datos de delitos');
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
      print('Error cargando datos: $e');
    }
  }

  void _toggle3D() {
    setState(() => _show3D = !_show3D);
    if (_show3D) {
      _scaleController.forward();
    } else {
      _scaleController.reverse();
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
                  Colors.red[700]!,
                  Colors.red[600]!,
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
                    Icons.threed_rotation,
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
                        'Mapa 3D',
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
                Switch(
                  value: _show3D,
                  onChanged: (value) => _toggle3D(),
                  activeColor: Colors.white,
                ),
              ],
            ),
          ),

          // Contenido del mapa
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildMapboxMap(colorScheme),
            ),
          ),

          // Controles
          if (_show3D) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              child: Column(
                children: [
                  // Zoom
                  Row(
                    children: [
                      Icon(Icons.zoom_in, color: colorScheme.onSurface, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _zoom,
                          min: 0.5,
                          max: 2.0,
                          divisions: 15,
                          onChanged: (value) {
                            setState(() => _zoom = value);
                          },
                          activeColor: Colors.red[700],
                          inactiveColor: Colors.grey[300],
                        ),
                      ),
                      Icon(Icons.zoom_out, color: colorScheme.onSurface, size: 20),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Rotación
                  Row(
                    children: [
                      Icon(Icons.rotate_left, color: colorScheme.onSurface, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Slider(
                          value: _rotationX,
                          min: -math.pi / 4,
                          max: math.pi / 4,
                          divisions: 8,
                          onChanged: (value) {
                            setState(() => _rotationX = value);
                          },
                          activeColor: Colors.red[700],
                          inactiveColor: Colors.grey[300],
                        ),
                      ),
                      Icon(Icons.rotate_right, color: colorScheme.onSurface, size: 20),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3);
  }

  Widget _buildMapboxMap(ColorScheme colorScheme) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: MapWidget(
            key: const ValueKey("mapWidget"),
            cameraOptions: CameraOptions(
              center: Point(coordinates: Position(widget.longitude, widget.latitude)),
              zoom: 16.0,
              pitch: _show3D ? 75.0 : 0.0,
              bearing: _show3D ? 45.0 : 0.0,
            ),
            styleUri: 'mapbox://styles/kevinroberto/cmgharq80006y01ryg3vl8zc5',
            onMapCreated: (MapboxMap mapboxMap) {
              print('🗺️ Mapa 3D de Mapbox creado correctamente');
              print('📍 Centro: ${widget.latitude}, ${widget.longitude}');
              print('🏙️ Ubicación: ${widget.locationName}');
            },
          ),
        ),
        
        // Herramientas de navegación 3D
        if (_show3D) ...[
          // Botón de rotación izquierda
          Positioned(
            top: 16,
            right: 16,
            child: _buildNavigationButton(
              icon: Icons.rotate_left,
              onPressed: () {
                setState(() {
                  _rotationY -= 15;
                });
              },
            ),
          ),
          
          // Botón de rotación derecha
          Positioned(
            top: 16,
            right: 60,
            child: _buildNavigationButton(
              icon: Icons.rotate_right,
              onPressed: () {
                setState(() {
                  _rotationY += 15;
                });
              },
            ),
          ),
          
          // Botón de inclinación hacia arriba
          Positioned(
            top: 60,
            right: 16,
            child: _buildNavigationButton(
              icon: Icons.keyboard_arrow_up,
              onPressed: () {
                setState(() {
                  _rotationX = (_rotationX + 15).clamp(-45.0, 45.0);
                });
              },
            ),
          ),
          
          // Botón de inclinación hacia abajo
          Positioned(
            top: 60,
            right: 60,
            child: _buildNavigationButton(
              icon: Icons.keyboard_arrow_down,
              onPressed: () {
                setState(() {
                  _rotationX = (_rotationX - 15).clamp(-45.0, 45.0);
                });
              },
            ),
          ),
          
          // Botón de zoom in
          Positioned(
            bottom: 16,
            right: 16,
            child: _buildNavigationButton(
              icon: Icons.zoom_in,
              onPressed: () {
                setState(() {
                  _zoom = (_zoom + 0.1).clamp(0.5, 2.0);
                });
              },
            ),
          ),
          
          // Botón de zoom out
          Positioned(
            bottom: 16,
            right: 60,
            child: _buildNavigationButton(
              icon: Icons.zoom_out,
              onPressed: () {
                setState(() {
                  _zoom = (_zoom - 0.1).clamp(0.5, 2.0);
                });
              },
            ),
          ),
          
          // Botón de reset
          Positioned(
            bottom: 16,
            left: 16,
            child: _buildNavigationButton(
              icon: Icons.refresh,
              onPressed: () {
                setState(() {
                  _rotationX = 0.0;
                  _rotationY = 0.0;
                  _zoom = 1.0;
                });
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onPressed,
          child: Icon(
            icon,
            color: Colors.grey[700],
            size: 20,
          ),
        ),
      ),
    );
  }

  Color _getCrimeColor(String crimeType) {
    // Color basado en el tipo de delito
    switch (crimeType.toLowerCase()) {
      case 'homicidio doloso':
        return Colors.red[900]!;
      case 'robo a casa habitación':
        return Colors.red[700]!;
      case 'robo a negocio':
        return Colors.orange[700]!;
      case 'robo a persona':
        return Colors.orange[600]!;
      case 'robo de vehículo':
        return Colors.amber[700]!;
      case 'violencia familiar':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

}

class Map3DPainter extends CustomPainter {
  final double centerLat;
  final double centerLng;
  final bool show3D;

  Map3DPainter({
    required this.centerLat,
    required this.centerLng,
    required this.show3D,
  });

  @override
  void paint(Canvas canvas, ui.Size size) {
    final paint = Paint();
    final center = Offset(size.width / 2, size.height / 2);

    // Dibujar fondo
    paint.color = Colors.grey[100]!;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);

    // Dibujar puntos de referencia (sin delitos)
    // Se pueden agregar puntos de interés locales aquí

    // Dibujar centro
    paint.color = Colors.blue;
    paint.style = PaintingStyle.fill;
    canvas.drawCircle(center, 8, paint);
    
    // Dibujar borde del centro
    paint.color = Colors.white;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawCircle(center, 8, paint);
  }

  Offset _latLngToOffset(double lat, double lng, ui.Size size) {
    // Conversión simplificada de lat/lng a offset
    final x = (lng - centerLng) * 100000 + size.width / 2;
    final y = (centerLat - lat) * 100000 + size.height / 2;
    return Offset(x, y);
  }

  double _getCrimeHeight(String crimeType) {
    // Altura basada en la gravedad del delito
    switch (crimeType.toLowerCase()) {
      case 'homicidio doloso':
        return 60.0;
      case 'robo a casa habitación':
        return 40.0;
      case 'robo a negocio':
        return 35.0;
      case 'robo a persona':
        return 30.0;
      case 'robo de vehículo':
        return 25.0;
      case 'violencia familiar':
        return 20.0;
      default:
        return 15.0;
    }
  }

  Color _getCrimeColor(String crimeType) {
    // Color basado en el tipo de delito
    switch (crimeType.toLowerCase()) {
      case 'homicidio doloso':
        return Colors.red[900]!;
      case 'robo a casa habitación':
        return Colors.red[700]!;
      case 'robo a negocio':
        return Colors.orange[700]!;
      case 'robo a persona':
        return Colors.orange[600]!;
      case 'robo de vehículo':
        return Colors.amber[700]!;
      case 'violencia familiar':
        return Colors.purple[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  void _draw3DBar(Canvas canvas, Paint paint, Offset base, double height, Color color) {
    // Dibujar la base
    paint.color = color;
    canvas.drawCircle(base, 3, paint);
    
    // Dibujar la barra 3D
    final top = Offset(base.dx, base.dy - height);
    
    // Sombra
    paint.color = color.withOpacity(0.3);
    canvas.drawLine(
      Offset(base.dx + 2, base.dy),
      Offset(top.dx + 2, top.dy),
      paint,
    );
    
    // Barra principal
    paint.color = color;
    paint.strokeWidth = 3;
    canvas.drawLine(base, top, paint);
    
    // Parte superior
    canvas.drawCircle(top, 3, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
