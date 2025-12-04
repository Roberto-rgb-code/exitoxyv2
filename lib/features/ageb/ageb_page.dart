// lib/features/ageb/ageb_page.dart
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../services/mysql_connector.dart';
import '../../shared/polygons_methods.dart';

class AgebPage extends StatefulWidget {
  const AgebPage({super.key});

  @override
  State<AgebPage> createState() => _AgebPageState();
}

class _AgebPageState extends State<AgebPage> {
  final _cpCtrl = TextEditingController(text: '44100');
  final Set<Polygon> _polygons = {};
  GoogleMapController? _map;
  bool _loading = false;

  static const _camera = CameraPosition(
    target: LatLng(20.6599162, -103.3450723), // GDL
    zoom: 11,
  );

  @override
  void dispose() {
    _cpCtrl.dispose();
    _map?.dispose();
    super.dispose();
  }

  Future<void> _drawByCP() async {
    var cp = _cpCtrl.text.trim();
    if (cp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe un código postal')),
      );
      return;
    }
    cp = cp.replaceAll(RegExp(r'[^0-9]'), '');

    setState(() {
      _loading = true;
      _polygons.clear();
    });

    try {
      final res = await MySQLConnector.getData(cp);
      final agebs = List<String>.from(res[0] as List);
      final geometries = List<dynamic>.from(res[1] as List);
      final demo = List<Map<String, dynamic>>.from(res[2] as List);
      
      print('🔍 Datos recibidos de MySQL para CP $cp:');
      print('  - AGEBs: ${agebs.length}');
      print('  - Geometrías: ${geometries.length}');
      print('  - Demografía: ${demo.length}');
      if (demo.isNotEmpty) {
        print('  - Primera demografía: ${demo[0]}');
      }

      final pm = PolygonsMethods();
      for (var i = 0; i < agebs.length; i++) {
        final coords = pm.geometry_data(geometries[i]);
        if (coords.length < 3) continue;

        _polygons.add(
          Polygon(
            polygonId: PolygonId(agebs[i]),
            points: coords,
            strokeColor: const Color(0xFF00BCD4), // Turquesa/cyan para el borde
            strokeWidth: 3, // Borde más grueso
            fillColor: const Color(0xFF00BCD4).withOpacity(0.4), // Relleno turquesa más visible
            consumeTapEvents: true,
            onTap: () {
              final d = demo[i];
              print('🔍 Datos demográficos para AGEB ${agebs[i]}: $d');
              showModalBottomSheet(
                context: context,
                builder: (_) => _AgebInfoSheet(data: d),
              );
            },
          ),
        );
      }

      setState(() {});
      if (_polygons.isNotEmpty && _map != null) {
        await _map!.animateCamera(
          CameraUpdate.newLatLngBounds(_boundsOf(_polygons.first.points), 40),
        );
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sin polígonos para ese CP')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  LatLngBounds _boundsOf(List<LatLng> pts) {
    double? minLat, maxLat, minLng, maxLng;
    for (final p in pts) {
      minLat = (minLat == null) ? p.latitude : (p.latitude < minLat ? p.latitude : minLat);
      maxLat = (maxLat == null) ? p.latitude : (p.latitude > maxLat ? p.latitude : maxLat);
      minLng = (minLng == null) ? p.longitude : (p.longitude < minLng ? p.longitude : minLng);
      maxLng = (maxLng == null) ? p.longitude : (p.longitude > maxLng ? p.longitude : maxLng);
    }
    return LatLngBounds(
      southwest: LatLng(minLat!, minLng!),
      northeast: LatLng(maxLat!, maxLng!),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.grid_on_rounded),
            SizedBox(width: 8),
            Text('AGEB por CP'),
          ],
        ),
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _camera,
            polygons: _polygons,
            onMapCreated: (c) => _map = c,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
          ),
          Positioned(
            left: 12,
            right: 12,
            top: MediaQuery.of(context).padding.top + 12,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.local_post_office_rounded),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _cpCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Código postal',
                        border: InputBorder.none,
                      ),
                      onSubmitted: (_) => _drawByCP(),
                    ),
                  ),
                  IconButton(
                    onPressed: _loading ? null : _drawByCP,
                    icon: _loading
                        ? const SizedBox(
                            width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.search_rounded),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AgebInfoSheet extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AgebInfoSheet({required this.data});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text('Datos AGEB', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _metric('Total', '${_safeParseInt(data['t'])}'),
                _metric('Hombres', '${_safeParseInt(data['m'])}'),
                _metric('Mujeres', '${_safeParseInt(data['f'])}'),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _metric(String label, String value) => Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      );

  /// Método helper para parsear int de forma segura
  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}
