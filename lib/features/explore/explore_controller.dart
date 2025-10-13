import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class ExploreController extends ChangeNotifier {
  /// Controlador del mapa de Google
  GoogleMapController? mapCtrl;

  /// Cámara inicial (Guadalajara)
  final CameraPosition initialCamera = const CameraPosition(
    target: LatLng(20.6599162, -103.3450723),
    zoom: 12.0,
  );

  /// Último punto “activo” (tap o geocodificación)
  LatLng? lastPoint;

  /// Polígonos a pintar (si usas AGEBS después)
  final Set<Polygon> polygons = <Polygon>{};

  /// Markers (negocios, selección, etc.)
  final Map<MarkerId, Marker> _markers = {};
  Set<Marker> allMarkers() => _markers.values.toSet();

  /// Flag para mostrar el “punto azul”
  bool myLocationEnabled = false;

  ExploreController() {
    // Inicializa permisos/ubicación al crear el controller
    ensureLocationReady();
  }

  // ─────────────────────────────
  // Hooks del GoogleMap
  // ─────────────────────────────

  void onMapCreated(GoogleMapController ctrl) {
    mapCtrl = ctrl;
  }

  void onCameraMove(CameraPosition cam) {
    // Si necesitas usar la cámara mientras se mueve, manéjalo aquí
  }

  Future<void> onMapTap(LatLng p) async {
    lastPoint = p;
    _addOrMoveSelectionMarker(p);
    notifyListeners();
  }

  Future<void> onMapLongPress(LatLng p) async {
    // Igual que tap, pero puedes diferenciar si quieres otro comportamiento
    lastPoint = p;
    _addOrMoveSelectionMarker(p);
    notifyListeners();
  }

  // ─────────────────────────────
  // Permisos y ubicación
  // ─────────────────────────────

  Future<void> ensureLocationReady() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        myLocationEnabled = false;
        notifyListeners();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        myLocationEnabled = false;
        notifyListeners();
        return;
      }

      // ✅ Permisos OK
      myLocationEnabled = true;
      notifyListeners();

      // (Opcional) mover cámara a tu ubicación actual
      // final pos = await Geolocator.getCurrentPosition();
      // await mapCtrl?.animateCamera(
      //   CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 14),
      // );
    } catch (_) {
      myLocationEnabled = false;
      notifyListeners();
    }
  }

  // ─────────────────────────────
  // Búsqueda por texto (geocoding)
  // ─────────────────────────────

  /// Busca una dirección y mueve la cámara. (Sin `localeIdentifier`, geocoding 4.x no lo acepta)
  Future<void> geocodeAndMove(String query) async {
    if (query.trim().isEmpty) return;

    final locs = await locationFromAddress(query); // 👈 SIN localeIdentifier
    if (locs.isEmpty) return;

    final loc = locs.first;
    final p = LatLng(loc.latitude, loc.longitude);
    lastPoint = p;

    _addOrMoveSelectionMarker(p);
    await mapCtrl?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: p, zoom: 16),
      ),
    );
    notifyListeners();
  }

  // ─────────────────────────────
  // Utilidades de markers
  // ─────────────────────────────

  Future<void> _addOrMoveSelectionMarker(LatLng p) async {
    const id = MarkerId('selection');
    BitmapDescriptor icon = BitmapDescriptor.defaultMarker;

    // Si quieres un asset:
    // icon = await BitmapDescriptor.fromAssetImage(
    //   const ImageConfiguration(),
    //   'assets/tu_icono.png',
    // );

    final marker = Marker(
      markerId: id,
      position: p,
      icon: icon,
      anchor: const Offset(0.5, 1),
      consumeTapEvents: false,
    );

    _markers[id] = marker;
  }

  // Si más adelante quieres limpiar markers/polígonos
  void clearAll() {
    _markers.clear();
    polygons.clear();
    lastPoint = null;
    notifyListeners();
  }
}
