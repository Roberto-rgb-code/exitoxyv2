import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../app/map_symbols.dart';
import '../../services/predio_service.dart';

class PredioPage extends StatefulWidget {
  const PredioPage({super.key});

  @override
  State<PredioPage> createState() => _PredioPageState();
}

class _PredioPageState extends State<PredioPage> {
  GoogleMapController? _map;
  Marker? _marker;

  static const _camera = CameraPosition(
    target: LatLng(20.6599162, -103.3450723), // GDL
    zoom: 14,
  );

  @override
  void dispose() {
    _map?.dispose();
    super.dispose();
  }

  Future<void> _onTap(LatLng p) async {
    // Mostrar indicador de carga
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Buscando información del predio...'),
        duration: Duration(seconds: 1),
      ),
    );

    // Crear icono personalizado estilo ArcGIS para selección
    final selectionIcon = await MapSymbols.getSelectionMarker();
    
    setState(() {
      _marker = Marker(
        markerId: const MarkerId('predio'),
        position: p,
        anchor: const Offset(0.5, 0.5),
        icon: selectionIcon,
      );
    });

    try {
      final info = await PredioService().fetchPredioByLatLng(p);
      if (!mounted) return;

      if (info == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró información del predio')),
        );
        return;
      }

      await showModalBottomSheet(
        context: context,
        isScrollControlled: false,
        builder: (_) => _PredioSheet(info: info),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final markers = <Marker>{};
    if (_marker != null) markers.add(_marker!);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            Icon(Icons.domain),
            SizedBox(width: 8),
            Text('Predio'),
          ],
        ),
      ),
      body: GoogleMap(
        initialCameraPosition: _camera,
        onMapCreated: (c) => _map = c,
        markers: markers,
        onTap: _onTap,
        myLocationButtonEnabled: false,
        zoomControlsEnabled: true,
      ),
    );
  }
}

class _PredioSheet extends StatelessWidget {
  final PredioInfo info;
  const _PredioSheet({required this.info});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text('Información de predio', style: t.titleMedium),
            const SizedBox(height: 12),
            ListTile(
              dense: true,
              title: const Text('Cuenta catastral'),
              trailing: Text(info.cuentaCatastral),
            ),
            ListTile(
              dense: true,
              title: const Text('Uso de suelo'),
              trailing: Text(info.usoDeSuelo),
            ),
            ListTile(
              dense: true,
              title: const Text('Superficie'),
              trailing: Text('${info.superficie.toStringAsFixed(0)} m²'),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(info.domicilio, style: t.bodyMedium),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
