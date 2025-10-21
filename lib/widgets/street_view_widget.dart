import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/google_street_view_service.dart';

class StreetViewWidget extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? locationName;

  const StreetViewWidget({
    super.key,
    required this.latitude,
    required this.longitude,
    this.locationName,
  });

  @override
  State<StreetViewWidget> createState() => _StreetViewWidgetState();
}

class _StreetViewWidgetState extends State<StreetViewWidget> {
  final GoogleStreetViewService _streetViewService = GoogleStreetViewService();
  bool _isAvailable = false;
  bool _isLoading = true;
  String _currentView = 'north';
  int _currentFov = 90;
  int _currentPitch = 0;

  final Map<String, String> _viewAngles = {
    'north': 'Norte',
    'east': 'Este',
    'south': 'Sur',
    'west': 'Oeste',
  };

  @override
  void initState() {
    super.initState();
    _checkAvailability();
  }

  Future<void> _checkAvailability() async {
    try {
      final available = await _streetViewService.isStreetViewAvailable(
        latitude: widget.latitude,
        longitude: widget.longitude,
      );
      
      setState(() {
        _isAvailable = available;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isAvailable = false;
        _isLoading = false;
      });
    }
  }

  void _changeView(String view) {
    setState(() => _currentView = view);
  }

  void _changeFov(int fov) {
    setState(() => _currentFov = fov);
  }

  void _changePitch(int pitch) {
    setState(() => _currentPitch = pitch);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (!_isAvailable) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.location_off,
                size: 48,
                color: Colors.grey[600],
              ),
              const SizedBox(height: 16),
              Text(
                'Street View no disponible',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Esta ubicación no tiene\nimágenes de Street View',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blue[700],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.streetview,
                  color: Colors.white,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.locationName ?? 'Street View',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Imagen de Street View
          Container(
            height: 300,
            width: double.infinity,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              child: Image.network(
                _streetViewService.getStreetViewAngles(
                  latitude: widget.latitude,
                  longitude: widget.longitude,
                  fov: _currentFov,
                )[_currentView]!,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(
                      child: Icon(
                        Icons.error,
                        size: 48,
                        color: Colors.red,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Controles
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Column(
              children: [
                // Selector de dirección
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: _viewAngles.entries.map((entry) {
                    final isSelected = _currentView == entry.key;
                    return GestureDetector(
                      onTap: () => _changeView(entry.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.blue[700] : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? Colors.blue[700]! : Colors.grey[300]!,
                          ),
                        ),
                        child: Text(
                          entry.value,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white : Colors.grey[700],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Controles de FOV y Pitch
                Row(
                  children: [
                    // FOV
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Zoom (FOV): $_currentFov°',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Slider(
                            value: _currentFov.toDouble(),
                            min: 60,
                            max: 120,
                            divisions: 6,
                            onChanged: (value) => _changeFov(value.round()),
                            activeColor: Colors.blue[700],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 16),

                    // Pitch
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Inclinación: $_currentPitch°',
                            style: GoogleFonts.poppins(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Slider(
                            value: _currentPitch.toDouble(),
                            min: -30,
                            max: 30,
                            divisions: 6,
                            onChanged: (value) => _changePitch(value.round()),
                            activeColor: Colors.blue[700],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
