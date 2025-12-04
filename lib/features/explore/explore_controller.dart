// lib/features/explore/explore_controller.dart
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import '../../app/map_symbols.dart';
import '../../shared/polygons_methods.dart';
import '../../services/ageb_api_service.dart';
import '../../services/mysql_connector.dart';
import '../../services/denue_repository.dart';
import '../../services/concentration_service.dart';
import '../../services/cache_service.dart';
import '../../services/recommendation_service.dart';
import '../../services/markers_commercial_service.dart';
import '../../services/filtering_service.dart';
import '../../models/concentration_result.dart';
import '../../widgets/custom_info_window.dart';
import '../../widgets/denue_info_window.dart';
import '../../widgets/polygon_window.dart';
import '../../widgets/delito_info_window.dart';
import '../../services/delitos_service.dart';
import '../../models/delito_model.dart';
import '../../models/recommendation.dart';
import '../../services/google_places_marketplace_service.dart';
import '../../models/marketplace_listing.dart';
import '../../services/postgres_gis_service.dart';
import '../../models/censo_ageb.dart';
import '../../models/estacion_transporte.dart';
import '../../models/linea_transporte.dart';
import '../../models/ruta_transporte.dart';

/// Cache local por CP
class ExploreLocalCache {
  static final _polygonsByCp = <String, List<Polygon>>{};
  static final _demoByCp = <String, Map<String, int>>{};

  static List<Polygon>? getPolygons(String cp) => _polygonsByCp[cp];
  static Map<String, int>? getDemo(String cp) => _demoByCp[cp];

  static void putPolygons(String cp, List<Polygon> polygons) {
    _polygonsByCp[cp] = polygons;
  }

  static void putDemo(String cp, Map<String, int> demo) {
    _demoByCp[cp] = demo;
  }

  static void clear() {
    _polygonsByCp.clear();
    _demoByCp.clear();
  }
}

class ExploreController extends ChangeNotifier {
  GoogleMapController? mapCtrl;
  CustomInfoWindowController? customInfoWindowController;

  final CameraPosition initialCamera = const CameraPosition(
    target: LatLng(20.6599162, -103.3450723),
    zoom: 12.0,
  );

  LatLng? lastPoint;
  final Set<Polygon> polygons = <Polygon>{};
  final Set<Polyline> polylines = <Polyline>{};
  final Map<MarkerId, Marker> _markers = {};
  Set<Marker> allMarkers() {
    final markers = _markers.values.toSet();
    print('🗺️ allMarkers() llamado: ${markers.length} marcadores');
    print('🗺️ Marcadores DENUE: ${_markers.keys.where((key) => key.value.startsWith('denue_')).length}');
    print('🗺️ Marcadores Delitos: ${_markers.keys.where((key) => key.value.startsWith('delito_')).length}');
    print('🗺️ Marcadores Google Places: ${_markers.keys.where((key) => key.value.startsWith('places_')).length}');
    return markers;
  }

  /// Agregar un marcador al mapa
  void addMarker(MarkerId markerId, Marker marker) {
    _markers[markerId] = marker;
    notifyListeners();
  }

  /// Remover un marcador del mapa
  void removeMarker(MarkerId markerId) {
    _markers.remove(markerId);
    notifyListeners();
  }

  bool myLocationEnabled = false;

  String? activeCP;
  Map<String, int>? demographyAgg; // {'t','m','f'}
  
  // Variables para análisis de concentración
  bool showConcentrationLayer = false;
  ConcentrationResult? currentConcentration;
  
  // Variables para Google Places
  List<MarketplaceListing> _googlePlacesData = [];
  bool _showGooglePlacesMarkers = false;
  String? currentActivity;
  
  // Variables para recomendaciones
  List<Recommendation> recommendations = [];
  
  // Variables para capas PostGIS
  bool _showPostgisAgebLayer = false;
  bool _showPostgisTransporteLayer = false; // Estaciones
  bool _showPostgisRutasLayer = false;
  bool _showPostgisLineasLayer = false;
  bool _showPostgisLayersPanel = false; // Control de visibilidad del panel
  final PostgresGisService _postgisService = PostgresGisService();
  final Map<String, dynamic> _postgisData = {};

  // Variables para marcadores comerciales
  bool hasPaintedAZone = false;
  int countMarkers = 0;
  List<Map<String, dynamic>> commercialData = [];
  Map<String, dynamic> filters = {
    'm2': null,
    'precio': null,
    'habitaciones': null,
    'banos': null,
    'garage': null,
  };
  
  // Variables para modal comercial
  Map<String, dynamic>? selectedCommercialData;
  LatLng? selectedCommercialPosition;

  /// Controlador principal de la experiencia de exploración.
  ///
  /// [autoEnsureLocation] se deja en `true` para la app normal, pero se puede
  /// desactivar en tests para evitar depender de plugins de ubicación.
  ExploreController({bool autoEnsureLocation = true}) {
    if (autoEnsureLocation) {
      ensureLocationReady();
    }
    customInfoWindowController = CustomInfoWindowController();
  }

  void onMapCreated(GoogleMapController ctrl) {
    mapCtrl = ctrl;
    customInfoWindowController?.googleMapController = ctrl;
  }

  void onCameraMove(CameraPosition _) {}

  Future<void> onMapTap(LatLng p) async {
    lastPoint = p;
    await _addOrMoveSelectionMarker(p);
    notifyListeners();
    await _pipelineFromLatLng(p);
  }

  Future<void> onMapLongPress(LatLng p) => onMapTap(p);

  Future<void> ensureLocationReady() async {
    try {
      final ok = await Geolocator.isLocationServiceEnabled();
      if (!ok) {
        myLocationEnabled = false;
        notifyListeners();
        return;
      }
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.denied ||
          perm == LocationPermission.deniedForever) {
        myLocationEnabled = false;
        notifyListeners();
        return;
      }
      myLocationEnabled = true;
      notifyListeners();
    } catch (_) {
      myLocationEnabled = false;
      notifyListeners();
    }
  }

  Future<void> geocodeAndMove(String query) async {
    if (query.trim().isEmpty) return;
    
    // Agregar "Guadalajara, Jal." por defecto si no se especifica ciudad
    String searchQuery = query.trim();
    if (!searchQuery.toLowerCase().contains('guadalajara') && 
        !searchQuery.toLowerCase().contains('jal') &&
        !searchQuery.toLowerCase().contains('jalisco')) {
      searchQuery = '$searchQuery, Guadalajara, Jal.';
    }
    
    final locs = await locationFromAddress(searchQuery);
    if (locs.isEmpty) return;

    final p = LatLng(locs.first.latitude, locs.first.longitude);
    lastPoint = p;

    await _addOrMoveSelectionMarker(p);
    await mapCtrl?.animateCamera(
      CameraUpdate.newCameraPosition(CameraPosition(target: p, zoom: 15.5)),
    );
    notifyListeners();
    await _pipelineFromLatLng(p);
  }

  Future<void> _pipelineFromLatLng(LatLng p) async {
    // 1) CP por reverse geocoding
    final placemarks = await placemarkFromCoordinates(p.latitude, p.longitude);
    final cp = placemarks.isNotEmpty ? placemarks.first.postalCode : null;
    if (cp == null || cp.isEmpty) return;

    // 2) cache
    final cachedPolys = ExploreLocalCache.getPolygons(cp);
    final cachedDemo = ExploreLocalCache.getDemo(cp);
    if (cachedPolys != null && cachedDemo != null) {
      polygons
        ..clear()
        ..addAll(cachedPolys);
      demographyAgg = cachedDemo;
      activeCP = cp;
      notifyListeners();
      return;
    }

    try {
      // 3) Obtener datos directamente de MySQL como en el código que funciona
      print('🔍 Buscando datos para CP: $cp');
      final resultados = await MySQLConnector.getData(cp);
      print('📊 Resultados obtenidos: ${resultados[0].length} AGEBs');
      
      if (resultados[0].length == 0) {
        // No hay datos para este CP
        print('❌ No hay datos para el CP: $cp');
        return;
      }

      // 4) parsear geometrías usando la misma lógica que funciona
      print('🔍 Datos recibidos de MySQL:');
      print('  - AGEBs: ${resultados[0]}');
      print('  - Geometrías: ${resultados[1].length} elementos');
      print('  - Demografía: ${resultados[2]}');
      if (resultados[1].isNotEmpty) {
        print('  - Primera geometría: ${resultados[1][0]}');
        print('  - Tipo de primera geometría: ${resultados[1][0].runtimeType}');
        print('  - Longitud de primera geometría: ${resultados[1][0].toString().length}');
        print('  - Primeros 200 caracteres: ${resultados[1][0].toString().substring(0, resultados[1][0].toString().length > 200 ? 200 : resultados[1][0].toString().length)}');
      }
      
      final resultPolys = _myPolygon(resultados);

      // 5) agregados demográficos
      int t = 0, m = 0, f = 0;
      for (final d in resultados[2]) {
        t += _safeParseInt(d['t']);
        m += _safeParseInt(d['m']);
        f += _safeParseInt(d['f']);
      }
      final demoAgg = {'t': t, 'm': m, 'f': f};

      // 6) estado + cache
      print('🎨 Creando ${resultPolys.length} polígonos en el mapa');
      polygons
        ..clear()
        ..addAll(resultPolys);
      demographyAgg = demoAgg;
      activeCP = cp;
      print('✅ Polígonos agregados al estado: ${polygons.length}');

      ExploreLocalCache.putPolygons(cp, resultPolys.toList());
      ExploreLocalCache.putDemo(cp, demoAgg);
      notifyListeners();

      // 7) Cargar marcadores comerciales
      if (!hasPaintedAZone) {
        // Necesitamos el contexto, pero lo pasaremos desde la UI
        hasPaintedAZone = true;
      }

      // 8) (opcional) Google Places cercanos – muestra 10
      if (polygons.isNotEmpty) {
        final center = polygons.first.points.first;
        await _fetchNearbyPlacesAt(center, keyword: 'tienda');
      }
    } catch (e) {
      print('Error cargando datos AGEB: $e');
      // Fallback a la API si MySQL falla
      try {
        final (agebs, geometries, demo) = await AgebApiService.getByCP(cp);
        // ... resto del código de fallback
      } catch (apiError) {
        print('Error también en API: $apiError');
      }
    }
  }

  Future<void> _loadCommercialMarkers(String cp, BuildContext context) async {
    try {
      // Obtener datos comerciales del MySQL
      final result = await MySQLConnector.connector.execute(
        'SELECT * FROM comercios WHERE cp = :cp',
        {'cp': cp},
      );

      commercialData = result.rows.map((row) => {
        'nombre': row.colByName('nombre')?.toString() ?? '',
        'descripcion': row.colByName('descripcion')?.toString() ?? '',
        'precio': row.colByName('precio')?.toString() ?? '',
        'lat': row.colByName('lat')?.toString() ?? '0',
        'lon': row.colByName('lon')?.toString() ?? '0',
        'superficie_m3': row.colByName('superficie_m3')?.toString() ?? '0',
        'num_cuartos': row.colByName('num_cuartos')?.toString() ?? '0',
        'num_banos': row.colByName('num_banos')?.toString() ?? '0',
        'num_cajones': row.colByName('num_cajones')?.toString() ?? '0',
      }).toList();

      // Crear marcadores comerciales (sólo datos; la simbología se define aquí)
      final markersService = MarkersCommercialService(commercialData);
      final markers = markersService.createCommercialMarkers();

      // Agregar marcadores al mapa con iconos personalizados estilo ArcGIS
      final commercialIcon = await MapSymbols.getCommercialMarker();
      for (int i = 0; i < commercialData.length; i++) {
        final data = commercialData[i];
        final markerId = MarkerId('commercial_$i');
        final marker = Marker(
          markerId: markerId,
          position: LatLng(
            double.parse(data['lat'] ?? '0'),
            double.parse(data['lon'] ?? '0'),
          ),
          icon: commercialIcon,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: '${MapSymbols.commercialEmoji} ${data['nombre'] ?? 'Comercio'}',
            snippet: data['descripcion'] ?? '',
          ),
          onTap: () => _showCommercialInfo(data),
        );
        _markers[markerId] = marker;
      }

      countMarkers = commercialData.length;
      notifyListeners();
    } catch (e) {
      print('Error cargando marcadores comerciales: $e');
    }
  }

  void _showCommercialInfo(Map<String, dynamic> data) {
    selectedCommercialData = data;
    selectedCommercialPosition = LatLng(
      double.parse(data['lat'] ?? '0'),
      double.parse(data['lon'] ?? '0'),
    );
    notifyListeners();
  }

  Future<void> _fetchNearbyPlacesAt(LatLng p, {required String keyword}) async {
    try {
      // Temporalmente comentado hasta integrar Google Places
      // final list = await GooglePlacesService.getPlacesNearby(keyword, p.latitude, p.longitude);
      // int i = 0;
      // for (final place in list.take(10)) {
      //   final id = MarkerId('place_$i');
      //   final marker = await GooglePlaceService.buildSimpleMarker(
      //     id.value,
      //     LatLng(place['lat'], place['lon']),
      //     place['nombre'],
      //   );
      //   _markers[id] = marker;
      //   i++;
      // }
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _addOrMoveSelectionMarker(LatLng p) async {
    const id = MarkerId('selection');
    
    // Crear un marcador de selección estilo ArcGIS (círculo con icono)
    final icon = await MapSymbols.getSelectionMarker();
    final marker = Marker(
      markerId: id,
      position: p,
      anchor: const Offset(0.5, 0.5),
      consumeTapEvents: false,
      icon: icon,
      zIndex: 2,
    );
    _markers[id] = marker;
  }

  /// Aplica filtros a los marcadores comerciales
  Future<void> applyFilters(Map<String, dynamic> newFilters) async {
    filters = newFilters;
    
    if (activeCP == null) return;

    try {
      // Obtener datos comerciales filtrados
      final filteredData = FilteringService.filterCommercialData(commercialData, filters);
      
      // Limpiar marcadores comerciales existentes
      _markers.removeWhere((key, marker) => key.value.startsWith('commercial_'));
      
      // Crear icono personalizado estilo ArcGIS para Comercios
      final commercialIcon = await MapSymbols.getCommercialMarker();
      
      // Crear nuevos marcadores filtrados
      for (int i = 0; i < filteredData.length; i++) {
        final data = filteredData[i];
        final markerId = MarkerId('commercial_$i');
        final marker = Marker(
          markerId: markerId,
          position: LatLng(
            double.parse(data['lat'] ?? '0'),
            double.parse(data['lon'] ?? '0'),
          ),
          icon: commercialIcon,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: '${MapSymbols.commercialEmoji} ${data['nombre'] ?? 'Comercio'}',
            snippet: data['descripcion'] ?? '',
          ),
          onTap: () => _showCommercialInfo(data),
        );
        _markers[markerId] = marker;
      }

      countMarkers = filteredData.length;
      notifyListeners();
    } catch (e) {
      print('Error aplicando filtros: $e');
    }
  }

  /// Limpia los filtros y restaura todos los marcadores
  Future<void> clearFilters() async {
    filters = FilteringService.clearFilters(filters);
    await applyFilters(filters);
  }

  /// Verifica si hay filtros activos
  bool hasActiveFilters() {
    return FilteringService.hasActiveFilters(filters);
  }

  /// Carga marcadores comerciales desde la UI
  Future<void> loadCommercialMarkers(BuildContext context) async {
    if (activeCP != null && !hasPaintedAZone) {
      await _loadCommercialMarkers(activeCP!, context);
    }
  }

  /// Limpia la selección del modal comercial
  void clearCommercialSelection() {
    selectedCommercialData = null;
    selectedCommercialPosition = null;
    notifyListeners();
  }

  /// Método helper para parsear int de forma segura
  int _safeParseInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Crea polígonos usando la misma lógica que funciona en el proyecto anterior
  Set<Polygon> _myPolygon(List listaGeometry) {
    final resultPolys = <Polygon>{};
    final pm = PolygonsMethods();
    
    print('🔧 Procesando ${listaGeometry[1].length} geometrías...');
    
    for (var i = 0; i < listaGeometry[1].length; i++) {
      List<LatLng> pts = [];
      
      try {
        // Intentar primero con el método del proyecto anterior
        print('🔄 Intentando geometry_data para geometría $i...');
        pts = pm.geometry_data(listaGeometry[1][i]);
        print('✅ geometry_data exitoso: ${pts.length} puntos');
      } catch (e) {
        print('❌ geometry_data falló: $e');
        try {
          // Fallback al método original
          print('🔄 Intentando geometryToLatLngList para geometría $i...');
          pts = pm.geometryToLatLngList(listaGeometry[1][i]);
          print('✅ geometryToLatLngList exitoso: ${pts.length} puntos');
        } catch (e2) {
          print('❌ geometryToLatLngList también falló: $e2');
          continue;
        }
      }
      
      if (pts.length < 3) {
        print('⚠️ Geometría $i descartada: menos de 3 puntos (${pts.length})');
        continue;
      }
      
      final agebId = listaGeometry[0][i].toString();
      final demoData = listaGeometry[2][i];
      
      final polygon = Polygon(
        geodesic: true,
        polygonId: PolygonId(agebId),
        points: pts,
        consumeTapEvents: true,
        zIndex: -1,
        strokeColor: const Color(0xFF00BCD4), // Turquesa/cyan para el borde
        strokeWidth: 5, // Borde más grueso como en el código que funciona
        fillColor: const Color(0xFF00BCD4).withOpacity(0.4), // Relleno turquesa más visible
        onTap: () => _showPolygonInfoWindow(agebId, demoData),
      );
      
      resultPolys.add(polygon);
      print('✅ Polígono $i creado exitosamente');
    }
    
    print('🎨 Creados ${resultPolys.length} polígonos');
    return resultPolys;
  }

  void clearAll() {
    _markers.clear();
    polygons.clear();
    lastPoint = null;
    activeCP = null;
    demographyAgg = null;
    showConcentrationLayer = false;
    currentConcentration = null;
    currentActivity = null;
    recommendations.clear();
    hasPaintedAZone = false;
    countMarkers = 0;
    commercialData.clear();
    filters = FilteringService.clearFilters(filters);
    selectedCommercialData = null;
    selectedCommercialPosition = null;
    customInfoWindowController?.hideInfoWindow?.call();
    notifyListeners();
  }

  void clearDemographicOverlay() {
    activeCP = null;
    demographyAgg = null;
    notifyListeners();
  }

  /// Analiza la concentración del mercado para una actividad específica
  Future<void> analyzeConcentration(String activity) async {
    if (lastPoint == null || activeCP == null) {
      throw Exception('Selecciona una zona primero (tap en el mapa o busca una dirección)');
    }

    currentActivity = activity;
    print('🔍 Analizando concentración para: $activity en CP: $activeCP');
    
    // Limpiar entradas de cache expiradas o con datos de fallback
    CacheService.cleanExpired();
    
    // Verificar cache
    final cached = CacheService.get(activity, activeCP!);
    if (cached != null) {
      print('✅ Usando datos en cache');
      currentConcentration = cached;
      showConcentrationLayer = true;
      
      // Generar recomendaciones aunque sea del cache
      await _generateRecommendations();
      
      // Cargar marcadores de Google Places (Propiedades)
      await loadGooglePlacesMarkers();
      
      // Mostrar marcadores DENUE (Actividades Económicas)
      await showDenueMarkers(activity);
      
      // Mostrar marcadores de delitos
      await showDelitosMarkers();
      
      notifyListeners();
      return;
    }

    try {
      print('📡 Obteniendo datos DENUE...');
      // Obtener datos DENUE
      final entries = await DenueRepository.fetchEntries(
        activity: activity,
        lat: lastPoint!.latitude,
        lon: lastPoint!.longitude,
        postalCode: activeCP,
      );

      print('📊 Encontrados ${entries.length} negocios');

      if (entries.isEmpty) {
        throw Exception('No se encontraron negocios de "$activity" en esta área');
      }

      // Calcular concentración
      final result = ConcentrationService.compute(
        entries: entries,
        activity: activity,
        postalCode: activeCP!,
      );

      print('📈 HHI: ${result.hhi}, CR4: ${result.cr4}');

      // Guardar en cache
      CacheService.put(activity, activeCP!, result);

      // Actualizar estado
      currentConcentration = result;
      showConcentrationLayer = true;
      
      // Generar recomendaciones
      await _generateRecommendations();
      
      // Cargar marcadores de Google Places (Propiedades)
      await loadGooglePlacesMarkers();
      
      // Mostrar marcadores DENUE (Actividades Económicas)
      await showDenueMarkers(activity);
      
      // Mostrar marcadores de delitos
      await showDelitosMarkers();

      print('✅ Análisis de concentración completado');
      notifyListeners();
    } catch (e) {
      print('❌ Error analizando concentración: $e');
      throw Exception('Error analizando concentración: $e');
    }
  }

  /// Genera recomendaciones basadas en el análisis actual
  Future<void> _generateRecommendations() async {
    try {
      print('💡 Generando recomendaciones...');
      
      if (lastPoint == null) {
        print('⚠️ No hay ubicación para generar recomendaciones');
        return;
      }

      final recommendationService = RecommendationService();
      recommendations = await recommendationService.generateRecommendations(
        latitude: lastPoint!.latitude,
        longitude: lastPoint!.longitude,
        locationName: activeCP != null 
            ? 'CP $activeCP, Guadalajara' 
            : 'Ubicación seleccionada',
      );

      print('✅ Generadas ${recommendations.length} recomendaciones');
    } catch (e) {
      print('⚠️ Error generando recomendaciones: $e');
      // No lanzar excepción, las recomendaciones son opcionales
      recommendations = [];
    }
  }

  /// Muestra marcadores DENUE con colores según concentración
  Future<void> showDenueMarkers(String activity) async {
    print('🔍 showDenueMarkers llamado con actividad: "$activity"');
    print('📍 lastPoint: $lastPoint');
    print('📍 activeCP: $activeCP');
    
    if (lastPoint == null) {
      print('⚠️ No hay ubicación para mostrar marcadores DENUE');
      return;
    }
    
    print('🎯 INICIANDO CREACIÓN DE MARCADORES DENUE...');

    try {
      print('🔍 Cargando marcadores DENUE para: "$activity"');
      print('📍 Coordenadas: lat=${lastPoint!.latitude}, lon=${lastPoint!.longitude}');
      
      final entries = await DenueRepository.fetchEntries(
        activity: activity,
        lat: lastPoint!.latitude,
        lon: lastPoint!.longitude,
        postalCode: activeCP,
        radius: 2000, // 2km de radio
      );

      print('📊 DENUE: ${entries.length} negocios encontrados');

      if (entries.isEmpty) {
        print('⚠️ No se encontraron negocios de "$activity" en esta área');
        return;
      }

      // Limpiar marcadores DENUE existentes
      final removedCount = _markers.keys.where((key) => key.value.startsWith('denue_')).length;
      _markers.removeWhere((key, marker) => key.value.startsWith('denue_'));
      print('🧹 Marcadores DENUE anteriores eliminados: $removedCount');

      // Color azul fijo para Actividades Económicas (simbología centralizada)
      double markerHue = MapSymbols.denueHue;
      print('🎨 Color de marcadores DENUE: Azul (fijo, MapSymbols.denueHue)');

      // Crear marcadores
      print('🎨 Creando ${entries.length} marcadores DENUE...');
      int createdCount = 0;
      for (int i = 0; i < entries.length; i++) {
        try {
          final entry = entries[i];
          final markerId = MarkerId('denue_${activity}_$i');
          
          if (i < 3) { // Debug primeros 3 marcadores
            print('📍 Marcador $i: ${entry.name} en ${entry.position}');
          }
          
          // Usar el nombre real del negocio (limpiar si es genérico)
          String displayName = entry.name.trim();
          // Detectar nombres genéricos como "abarrotes 1", "abarrotes 2", etc.
          final isGeneric = displayName.toLowerCase().startsWith(activity.toLowerCase()) && 
              RegExp(r'\s+\d+$').hasMatch(displayName);
          
          // Si es genérico, mostrar la actividad económica con formato mejorado
          if (isGeneric || displayName.isEmpty) {
            displayName = entry.activity.isNotEmpty 
                ? entry.activity 
                : 'Negocio';
          }
          
          final marker = Marker(
            markerId: markerId,
            position: entry.position,
            icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
            infoWindow: InfoWindow(
              title: '${MapSymbols.denueEmoji} ${displayName.isNotEmpty ? displayName : entry.activity}',
              snippet: '📍 ${entry.activity} • Tap para más información',
            ),
            onTap: () => _showDenueInfoWindow(entry),
          );

          _markers[markerId] = marker;
          createdCount++;
        } catch (e) {
          print('⚠️ Error creando marcador $i: $e');
          // Continuar con el siguiente marcador
        }
      }
      
      print('🎯 MARCADORES DENUE CREADOS: $createdCount de ${entries.length}');
      print('📊 Total de marcadores en el mapa: ${_markers.length}');
      print('📊 Marcadores DENUE: ${_markers.keys.where((key) => key.value.startsWith('denue_')).length}');
      
      // Debugging: mostrar algunos marcadores
      if (entries.isNotEmpty) {
        print('📍 Primer marcador: ${entries[0].name} en ${entries[0].position}');
        if (entries.length > 1) {
          print('📍 Segundo marcador: ${entries[1].name} en ${entries[1].position}');
        }
      }
      
      print('🔄 Notificando listeners...');
      notifyListeners();
      print('✅ DENUE: $createdCount marcadores agregados y notificados');
    } catch (e, stackTrace) {
      print('❌ Error mostrando marcadores DENUE: $e');
      print('📚 Stack trace: $stackTrace');
      // No rethrow para que no interrumpa el flujo, pero loguear el error
    }
  }

  /// Muestra marcadores de delitos en el mapa
  Future<void> showDelitosMarkers() async {
    if (lastPoint == null) {
      print('⚠️ No hay ubicación para mostrar marcadores de delitos');
      return;
    }

    try {
      print('🔍 Cargando marcadores de delitos...');
      
      // Obtener el servicio de delitos
      final delitosService = DelitosService();
      
      // Cargar delitos si no están cargados
      if (!delitosService.isLoaded) {
        print('📥 Cargando base de datos de delitos desde CSV...');
        await delitosService.loadDelitosFromCsv();
      }
      
      // Obtener delitos en un radio de 2km
      final delitos = delitosService.getDelitosByLocation(
        latitude: lastPoint!.latitude,
        longitude: lastPoint!.longitude,
        radiusMeters: 2000, // 2km de radio
      );

      print('📊 DELITOS: ${delitos.length} delitos encontrados en 2km');

      if (delitos.isEmpty) {
        print('✅ No hay delitos registrados en esta área (¡buena señal!)');
        // No retornar, solo notificar que no hay delitos
      }

      // Limpiar marcadores de delitos existentes
      _markers.removeWhere((key, marker) => key.value.startsWith('delito_'));

      // Limitar a máximo 50 marcadores para no saturar el mapa
      final delitosToShow = delitos.take(50).toList();
      
      if (delitosToShow.length < delitos.length) {
        print('⚠️ Mostrando solo ${delitosToShow.length} de ${delitos.length} delitos para optimizar rendimiento');
      }

      // Crear icono personalizado estilo ArcGIS para Delitos
      final delitoIcon = await MapSymbols.getDelitoMarker();
      print('🔴 Creando ${delitosToShow.length} marcadores de delitos (estilo ArcGIS)...');
      for (int i = 0; i < delitosToShow.length; i++) {
        final delito = delitosToShow[i];
        final markerId = MarkerId('delito_$i');

        if (i < 3) { // Debug primeros 3 marcadores
          print('🔴 Marcador delito $i: ${delito.delito} en (${delito.y}, ${delito.x})');
        }

        final marker = Marker(
          markerId: markerId,
          position: LatLng(delito.y, delito.x), // y=latitud, x=longitud
          icon: delitoIcon,
          anchor: const Offset(0.5, 0.5),
          infoWindow: InfoWindow(
            title: '${MapSymbols.delitoEmoji} ${delito.delito}',
            snippet: '📅 ${delito.fecha} • Tap para detalles',
          ),
          onTap: () => _showDelitoInfoWindow(delito),
        );

        _markers[markerId] = marker;
      }
      
      print('🎯 MARCADORES DE DELITOS AGREGADOS AL MAPA: ${_markers.length}');

      print('✅ DELITOS: ${delitosToShow.length} marcadores agregados al mapa');
      notifyListeners();
    } catch (e) {
      print('❌ Error mostrando marcadores de delitos: $e');
      // No lanzar excepción, los delitos son informativos pero no críticos
    }
  }

  /// Muestra información de un polígono AGEB
  void _showPolygonInfoWindow(String agebId, Map<String, dynamic> data) {
    customInfoWindowController?.addInfoWindow?.call(
      PolygonWindow(
        data: data,
        listaPolygons: polygons,
      ),
      polygons.first.points.first, // Usar el primer punto del polígono
    );
  }

  /// Muestra información de un punto DENUE
  void _showDenueInfoWindow(MarketEntry entry) {
    customInfoWindowController?.addInfoWindow?.call(
      DenueInfoWindow(
        name: entry.name,
        description: entry.description,
        activity: entry.activity,
        concentrationResult: currentConcentration,
        controller: customInfoWindowController,
      ),
      entry.position,
    );
  }

  /// Muestra información de un delito
  void _showDelitoInfoWindow(DelitoModel delito) {
    customInfoWindowController?.addInfoWindow?.call(
      DelitoInfoWindow(
        delito: delito.delito,
        fecha: delito.fecha,
        hora: delito.hora,
        colonia: delito.colonia,
        municipio: delito.municipio,
        bienAfectado: delito.bienAfectado,
        controller: customInfoWindowController,
      ),
      LatLng(delito.y, delito.x),
    );
  }
  
  /// Muestra información de un lugar de Google Places
  void _showGooglePlaceInfoWindow(MarketplaceListing place) {
    customInfoWindowController?.addInfoWindow?.call(
      _GooglePlaceInfoWindow(
        place: place,
        controller: customInfoWindowController,
      ),
      LatLng(place.latitude, place.longitude),
    );
  }
  
  /// Muestra información de una Colonia PostGIS
  void _showPostgisAgebInfoWindow(Map<String, dynamic> data) {
    try {
      final ageb = CensoAgeb.fromJson(data);
      final centroid = ageb.centroid;
      if (centroid != null) {
        customInfoWindowController?.addInfoWindow?.call(
          _PostgisAgebInfoWindow(
            ageb: ageb, 
            controller: customInfoWindowController,
          ),
          LatLng(centroid['latitude']!, centroid['longitude']!),
        );
      }
    } catch (e) {
      print('❌ Error mostrando info Colonia PostGIS: $e');
    }
  }
  
  /// Muestra información de una estación de transporte
  void _showEstacionInfoWindow(EstacionTransporte estacion) {
    final coords = estacion.coordinates;
    if (coords != null) {
      customInfoWindowController?.addInfoWindow?.call(
        _EstacionInfoWindow(
          estacion: estacion,
          controller: customInfoWindowController,
        ),
        LatLng(coords['latitude']!, coords['longitude']!),
      );
    }
  }
  
  /// Muestra información de una ruta de transporte
  void _showRutaInfoWindow(Map<String, dynamic> data, LatLng? position) {
    if (position != null) {
      customInfoWindowController?.addInfoWindow?.call(
        _RutaInfoWindow(
          data: data,
          controller: customInfoWindowController,
        ),
        position,
      );
    }
  }
  
  /// Muestra información de una línea de transporte masivo
  void _showLineaInfoWindow(Map<String, dynamic> data, LatLng? position) {
    if (position != null) {
      customInfoWindowController?.addInfoWindow?.call(
        _LineaInfoWindow(
          data: data,
          controller: customInfoWindowController,
        ),
        position,
      );
    }
  }
  
  /// Helper para convertir a int
  int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is String) return int.tryParse(value);
    return null;
  }

  /// Helper para convertir a double
  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Genera un color único basado en un ID
  Color _getColorForId(int id, List<Color> colorPalette) {
    return colorPalette[id % colorPalette.length];
  }

  /// Convierte un color a hue para BitmapDescriptor
  double _colorToHue(Color color) {
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    if (color == Colors.blue) return BitmapDescriptor.hueBlue;
    return BitmapDescriptor.hueBlue; // Default
  }

  /// Obtiene polígonos con colores según concentración
  Set<Polygon> getPolygonsWithConcentration() {
    print('🗺️ getPolygonsWithConcentration: ${polygons.length} polígonos disponibles');
    if (!showConcentrationLayer || currentConcentration == null) {
      print('📍 Devolviendo polígonos normales: ${polygons.length}');
      return polygons;
    }

    final coloredPolygons = <Polygon>{};
    for (final polygon in polygons) {
      coloredPolygons.add(Polygon(
        polygonId: polygon.polygonId,
        points: polygon.points,
        holes: polygon.holes,
        geodesic: polygon.geodesic,
        zIndex: polygon.zIndex,
        visible: polygon.visible,
        consumeTapEvents: polygon.consumeTapEvents,
        onTap: polygon.onTap,
        strokeWidth: polygon.strokeWidth,
        strokeColor: Color(currentConcentration!.color),
        fillColor: Color(currentConcentration!.color).withOpacity(0.3),
      ));
    }
    return coloredPolygons;
  }

  /// Convierte polígonos de Google Maps a formato GeoJSON para Mapbox 3D
  List<Map<String, dynamic>> getPolygonsFor3D() {
    final features = <Map<String, dynamic>>[];
    
    for (final polygon in polygons) {
      final coordinates = polygon.points.map((point) => [point.longitude, point.latitude]).toList();
      
      features.add({
        'type': 'Feature',
        'properties': {
          'id': polygon.polygonId.value,
          'fill': '#00BCD4',
          'stroke': '#00BCD4',
          'stroke-width': 3,
          'fill-opacity': 0.4,
        },
        'geometry': {
          'type': 'Polygon',
          'coordinates': [coordinates],
        },
      });
    }
    
    print('🗺️ Convertidos ${features.length} polígonos para 3D');
    return features;
  }

  /// Oculta solo el panel de leyenda (sin ocultar marcadores ni capas)
  void hideConcentrationLayer() {
    // Solo ocultar el panel, NO eliminar marcadores ni limpiar datos
    // Los marcadores y polígonos permanecen visibles en el mapa
    showConcentrationLayer = false;
    notifyListeners();
  }

  /// Carga marcadores de Google Places (Propiedades en renta/venta)
  Future<void> loadGooglePlacesMarkers({
    double radius = 5000,
  }) async {
    // Verificar si Google Places está configurado
    if (!GooglePlacesMarketplaceService.isConfigured) {
      print('⚠️ Google Places API no configurada - Saltando propiedades');
      _googlePlacesData = [];
      _showGooglePlacesMarkers = false;
      return;
    }
    
    try {
      print('🏠 Cargando propiedades (Google Places)...');
      
      // Determinar coordenadas
      double lat;
      double lng;
      
      if (lastPoint != null) {
        lat = lastPoint!.latitude;
        lng = lastPoint!.longitude;
        print('📍 Coordenadas: $lat, $lng');
      } else {
        print('⚠️ No hay ubicación seleccionada para buscar propiedades');
        return;
      }
      
      // Buscar propiedades con Google Places (sin datos ficticios)
      _googlePlacesData = await GooglePlacesMarketplaceService.searchComprehensive(
        latitude: lat,
        longitude: lng,
        radius: radius,
        limit: 15,
      );
      
      if (_googlePlacesData.isNotEmpty) {
        print('✅ Propiedades reales encontradas: ${_googlePlacesData.length}');
        await _createGooglePlacesMarkers();
        _showGooglePlacesMarkers = true;
      } else {
        print('ℹ️ No hay propiedades disponibles (API sin resultados o no configurada)');
        _showGooglePlacesMarkers = false;
      }
      
      notifyListeners();
      
    } catch (e) {
      print('❌ Error cargando propiedades: $e');
      _googlePlacesData = [];
      _showGooglePlacesMarkers = false;
    }
  }

  /// Crea marcadores de Google Places con iconos personalizados estilo ArcGIS
  Future<void> _createGooglePlacesMarkers() async {
    // Limpiar marcadores anteriores de Google Places
    _markers.removeWhere((key, marker) => key.value.startsWith('places_'));
    
    // Crear icono personalizado estilo ArcGIS para Propiedades
    final placeIcon = await MapSymbols.getPlaceMarker();
    
    for (int i = 0; i < _googlePlacesData.length; i++) {
      final place = _googlePlacesData[i];
      final markerId = MarkerId('places_$i');
      
      final marker = Marker(
        markerId: markerId,
        position: LatLng(place.latitude, place.longitude),
        icon: placeIcon,
        anchor: const Offset(0.5, 0.5),
        infoWindow: InfoWindow(
          title: '${MapSymbols.placesEmoji} ${place.title}',
          snippet: '💰 \$${place.price.toStringAsFixed(0)} • ${place.category}',
        ),
        onTap: () => _onGooglePlaceMarkerTap(place),
      );
      
      _markers[markerId] = marker;
    }
    
    print('✅ Google Places: ${_googlePlacesData.length} marcadores creados (estilo ArcGIS)');
  }

  /// Maneja el tap en marcadores de Google Places
  void _onGooglePlaceMarkerTap(MarketplaceListing place) {
    print('📍 Marcador Google Places tap: ${place.title}');
    _showGooglePlaceInfoWindow(place);
  }

  /// Alterna la visibilidad de marcadores de Google Places
  Future<void> toggleGooglePlacesMarkers() async {
    _showGooglePlacesMarkers = !_showGooglePlacesMarkers;
    
    if (_showGooglePlacesMarkers) {
      await _createGooglePlacesMarkers();
    } else {
      _markers.removeWhere((key, marker) => key.value.startsWith('places_'));
    }
    
    notifyListeners();
  }

  /// Obtiene el estado de visibilidad de Google Places
  bool get showGooglePlacesMarkers => _showGooglePlacesMarkers;

  // ============================================================
  // CAPAS POSTGIS
  // ============================================================

  /// Carga y muestra capas PostGIS (Colonias, Estaciones, Rutas, Líneas)
  Future<void> loadPostgisLayers({
    bool showAgeb = false, 
    bool showTransporte = false,
    bool showRutas = false,
    bool showLineas = false,
  }) async {
    // Guardar estados anteriores para detectar cambios
    final wasAgebActive = _showPostgisAgebLayer;
    final wasTransporteActive = _showPostgisTransporteLayer;
    final wasRutasActive = _showPostgisRutasLayer;
    final wasLineasActive = _showPostgisLineasLayer;
    
    // Actualizar estados
    _showPostgisAgebLayer = showAgeb;
    _showPostgisTransporteLayer = showTransporte;
    _showPostgisRutasLayer = showRutas;
    _showPostgisLineasLayer = showLineas;
    
    // Mostrar el panel cuando se activa una capa
    if (showAgeb || showTransporte || showRutas || showLineas) {
      _showPostgisLayersPanel = true;
    }
    
    // Limpiar capas que ahora están ocultas
    if (!showAgeb && wasAgebActive) {
      polygons.removeWhere((p) => p.polygonId.value.startsWith('postgis_ageb_'));
    }
    if (!showTransporte && wasTransporteActive) {
      _markers.removeWhere((key, marker) => key.value.startsWith('postgis_estacion_'));
    }
    if (!showRutas && wasRutasActive) {
      polylines.removeWhere((p) => p.polylineId.value.startsWith('postgis_ruta_'));
    }
    if (!showLineas && wasLineasActive) {
      polylines.removeWhere((p) => p.polylineId.value.startsWith('postgis_linea_'));
    }
    
    // SOLO cargar capas que se están activando (cambiando de false a true)
    // No recargar capas que ya estaban activas
    if (showAgeb && !wasAgebActive) {
      await _loadAgebPostgisLayer();
    }
    
    if (showTransporte && !wasTransporteActive) {
      await _loadTransportePostgisLayer();
    }
    
    if (showRutas && !wasRutasActive) {
      await _loadRutasPostgisLayer();
    }
    
    if (showLineas && !wasLineasActive) {
      await _loadLineasPostgisLayer();
    }
    
    notifyListeners();
  }

  /// Carga capa de Colonias desde PostGIS
  Future<void> _loadAgebPostgisLayer() async {
    try {
      print('🔍 Cargando capa de Colonias PostGIS (TODAS las colonias)...');
      
      // Cargar TODAS las colonias sin límite ni filtro de bounds
      final agebData = await _postgisService.getAllAgeb();
      
      print('✅ Colonias: ${agebData.length} áreas cargadas (TODAS)');
      
      // Limpiar colonias PostGIS anteriores
      polygons.removeWhere((p) => p.polygonId.value.startsWith('postgis_ageb_'));
      
      // Convertir GeoJSON a Polygon
      final pm = PolygonsMethods();
      
      // Calcular población min/max para coloreado
      int? minPob, maxPob;
      final pobTots = agebData.where((d) => d['POBTOT'] != null)
          .map((d) => _toInt(d['POBTOT']))
          .where((p) => p != null)
          .cast<int>()
          .toList();
      
      if (pobTots.isNotEmpty) {
        minPob = pobTots.reduce((a, b) => a < b ? a : b);
        maxPob = pobTots.reduce((a, b) => a > b ? a : b);
        print('📊 Población Colonias: min=$minPob, max=$maxPob');
      }
      
      for (int i = 0; i < agebData.length; i++) {
        final data = agebData[i];
        final geomJson = data['geom_json'] as String?;
        
        if (geomJson != null && geomJson.isNotEmpty) {
          try {
            final geoJsonMap = json.decode(geomJson) as Map<String, dynamic>;
            final pts = pm.geometryToLatLngList(geoJsonMap);
            
            if (pts.length >= 3) {
              // Determinar color según población
              Color fillColor = Colors.blue.withOpacity(0.2);
              Color strokeColor = Colors.blue;
              
              if (minPob != null && maxPob != null && minPob != maxPob) {
                final pobtot = _toInt(data['POBTOT']);
                if (pobtot != null) {
                  // Gradiente de azul claro a azul oscuro según población
                  final ratio = (pobtot - minPob) / (maxPob - minPob);
                  final intensity = (ratio * 255).toInt().clamp(50, 255);
                  strokeColor = Color.fromARGB(255, 0, 100, intensity);
                  fillColor = Color.fromARGB(50, 0, 100, intensity);
                }
              }
              
              final polygon = Polygon(
                polygonId: PolygonId('postgis_ageb_$i'),
                points: pts,
                fillColor: fillColor,
                strokeColor: strokeColor,
                strokeWidth: 2,
                geodesic: true,
                consumeTapEvents: true,
                onTap: () => _showPostgisAgebInfoWindow(data),
              );
              polygons.add(polygon);
            }
          } catch (e) {
            print('⚠️ Error parseando AGEB $i: $e');
          }
        }
      }
      
      _postgisData['ageb'] = agebData;
      print('✅ Total polígonos después de Colonias PostGIS: ${polygons.length}');
      notifyListeners();
      
    } catch (e) {
      print('❌ Error cargando Colonias PostGIS: $e');
    }
  }

  /// Carga capas de transporte (estaciones) desde PostGIS
  Future<void> _loadTransportePostgisLayer() async {
    try {
      print('🔍 Cargando estaciones de transporte PostGIS (TODAS)...');
      
      // Cargar TODAS las estaciones sin límite
      final estacionesData = await _postgisService.getEstacionesTransporte(limit: 10000);
      print('✅ Estaciones: ${estacionesData.length} cargadas (TODAS)');
      
      // Crear icono personalizado estilo ArcGIS para Estaciones
      final stationIcon = await MapSymbols.getStationMarker();
      
      // Crear marcadores de estaciones
      _markers.removeWhere((key, marker) => key.value.startsWith('postgis_estacion_'));
      for (int i = 0; i < estacionesData.length; i++) {
        final estacion = EstacionTransporte.fromJson(estacionesData[i]);
        final coords = estacion.coordinates;
        
        if (coords != null) {
          final markerId = MarkerId('postgis_estacion_$i');
          final marker = Marker(
            markerId: markerId,
            position: LatLng(coords['latitude']!, coords['longitude']!),
            icon: stationIcon,
            anchor: const Offset(0.5, 0.5),
            infoWindow: InfoWindow(
              title: '${MapSymbols.stationEmoji} ${estacion.nombre ?? "Estación"}',
              snippet: '${estacion.sistema ?? ""} • ${estacion.estado ?? ""}',
            ),
            onTap: () => _showEstacionInfoWindow(estacion),
          );
          _markers[markerId] = marker;
        }
      }
      
      // Guardar datos
      _postgisData['estaciones'] = estacionesData;
      print('✅ ${_markers.length} marcadores de estaciones agregadas');
      notifyListeners();
      
    } catch (e) {
      print('❌ Error cargando estaciones PostGIS: $e');
    }
  }
  
  /// Carga capa de rutas desde PostGIS
  Future<void> _loadRutasPostgisLayer() async {
    try {
      print('🔍 Cargando rutas de transporte PostGIS (TODAS)...');
      
      // Cargar TODAS las rutas sin límite
      final rutasData = await _postgisService.getRutasTransporte(limit: 10000);
      print('✅ Rutas: ${rutasData.length} cargadas (TODAS)');
      
      // Limpiar polylines de rutas anteriores
      polylines.removeWhere((p) => p.polylineId.value.startsWith('postgis_ruta_'));
      
      // Contador para polylines agregadas
      int addedCount = 0;
      
      // Convertir GeoJSON a Polyline
      final pm = PolygonsMethods();
      for (int i = 0; i < rutasData.length; i++) {
        final data = rutasData[i];
        final geomJson = data['geom_json'] as String?;
        final folderPath = data['FOLDERPATH']?.toString().toLowerCase() ?? '';
        
        if (geomJson != null && geomJson.isNotEmpty) {
          try {
            final geoJsonMap = json.decode(geomJson) as Map<String, dynamic>;
            final type = geoJsonMap['type']?.toString().toLowerCase();
            
            if (type == 'multilinestring' || type == 'linestring') {
              List<LatLng> pts = [];
              if (type == 'multilinestring') {
                final coords = geoJsonMap['coordinates'] as List?;
                if (coords != null && coords.isNotEmpty) {
                  final firstLine = coords.first;
                  for (final coord in firstLine) {
                    if (coord is List && coord.length >= 2) {
                      final lng = (coord[0] as num).toDouble();
                      final lat = (coord[1] as num).toDouble();
                      pts.add(LatLng(lat, lng));
                    }
                  }
                }
              } else {
                pts = pm.geometryToLatLngList(geoJsonMap);
              }
              
              if (pts.length >= 2) {
                // Color único por cada ruta basado en ID
                final routeId = _toInt(data['id']) ?? i;
                final orangePalette = [
                  Colors.orange,
                  Colors.deepOrange,
                  Colors.orange.shade700,
                  Colors.deepOrange.shade700,
                  Colors.deepOrange.shade900,
                  Colors.orange.shade800,
                  Colors.deepOrange.shade600,
                  Colors.orange.shade600,
                ];
                final routeColor = _getColorForId(routeId, orangePalette);
                
                final polyline = Polyline(
                  polylineId: PolylineId('postgis_ruta_$i'),
                  points: pts,
                  color: routeColor,
                  width: 5, // Aumentar ancho para mejor visibilidad
                  geodesic: true,
                  patterns: [], // Sin patrones
                  visible: true,
                  consumeTapEvents: true,
                  onTap: () => _showRutaInfoWindow(data, pts.isNotEmpty ? pts.first : null),
                );
                polylines.add(polyline);
                addedCount++;
                print('✅ Polyline ruta $i agregada: ${pts.length} puntos, color=${routeColor.value.toRadixString(16)}');
              }
            }
          } catch (e) {
            print('⚠️ Error parseando ruta $i: $e');
          }
        }
      }
      
      _postgisData['rutas'] = rutasData;
      print('✅ $addedCount polylines de rutas agregadas (total: ${polylines.length})');
      notifyListeners();
      
    } catch (e) {
      print('❌ Error cargando rutas PostGIS: $e');
    }
  }
  
  /// Carga capa de líneas de transporte masivo desde PostGIS
  Future<void> _loadLineasPostgisLayer() async {
    try {
      print('🔍 Cargando líneas de transporte masivo PostGIS (TODAS)...');
      
      // Cargar TODAS las líneas sin límite
      final lineasData = await _postgisService.getLineasTransporte(limit: 10000);
      print('✅ Líneas: ${lineasData.length} cargadas (TODAS)');
      
      // Limpiar polylines de líneas anteriores
      polylines.removeWhere((p) => p.polylineId.value.startsWith('postgis_linea_'));
      
      // Contador para polylines agregadas
      int addedCount = 0;
      
      // Convertir GeoJSON MultiLineString a Polyline
      final pm = PolygonsMethods();
      for (int i = 0; i < lineasData.length; i++) {
        final data = lineasData[i];
        final geomJson = data['geom_json'] as String?;
        final tipoCo = data['Tipo_de_co']?.toString().toLowerCase() ?? '';
        
        if (geomJson != null && geomJson.isNotEmpty) {
          try {
            final geoJsonMap = json.decode(geomJson) as Map<String, dynamic>;
            final type = geoJsonMap['type']?.toString().toLowerCase();
            
            if (type == 'multilinestring' || type == 'linestring') {
              List<LatLng> pts = [];
              if (type == 'multilinestring') {
                final coords = geoJsonMap['coordinates'] as List?;
                if (coords != null && coords.isNotEmpty) {
                  final firstLine = coords.first;
                  for (final coord in firstLine) {
                    if (coord is List && coord.length >= 2) {
                      final lng = (coord[0] as num).toDouble();
                      final lat = (coord[1] as num).toDouble();
                      pts.add(LatLng(lat, lng));
                    }
                  }
                }
              } else {
                pts = pm.geometryToLatLngList(geoJsonMap);
              }
              
              if (pts.length >= 2) {
                // Color único por cada línea basado en ID
                final lineaId = _toInt(data['id']) ?? i;
                final redPalette = [
                  Colors.red,
                  Colors.red.shade700,
                  Colors.red.shade400,
                  Colors.red[900]!,
                  Colors.red.shade800,
                  Colors.red.shade600,
                  Colors.red.shade300,
                  Colors.red.shade500,
                ];
                final lineaColor = _getColorForId(lineaId, redPalette);
                
                final polyline = Polyline(
                  polylineId: PolylineId('postgis_linea_$i'),
                  points: pts,
                  color: lineaColor,
                  width: 6, // Aumentar ancho para mejor visibilidad
                  geodesic: true,
                  patterns: [], // Sin patrones
                  visible: true,
                  consumeTapEvents: true,
                  onTap: () => _showLineaInfoWindow(data, pts.isNotEmpty ? pts.first : null),
                );
                polylines.add(polyline);
                addedCount++;
                print('✅ Polyline línea $i agregada: ${pts.length} puntos, color=${lineaColor.value.toRadixString(16)}');
              }
            }
          } catch (e) {
            print('⚠️ Error parseando línea $i: $e');
          }
        }
      }
      
      _postgisData['lineas'] = lineasData;
      print('✅ $addedCount polylines de líneas agregadas (total: ${polylines.length})');
      notifyListeners();
      
    } catch (e) {
      print('❌ Error cargando líneas PostGIS: $e');
    }
  }

  /// Oculta todas las capas PostGIS
  void hidePostgisLayers() {
    _showPostgisAgebLayer = false;
    _showPostgisTransporteLayer = false;
    _showPostgisRutasLayer = false;
    _showPostgisLineasLayer = false;
    // Limpiar marcadores PostGIS
    _markers.removeWhere((key, marker) => 
      key.value.startsWith('postgis_estacion_')
    );
    // Limpiar polígonos AGEB PostGIS
    polygons.removeWhere((p) => p.polygonId.value.startsWith('postgis_ageb_'));
    // Limpiar polylines PostGIS
    polylines.removeWhere((p) => 
      p.polylineId.value.startsWith('postgis_ruta_') || 
      p.polylineId.value.startsWith('postgis_linea_')
    );
    notifyListeners();
  }

  /// Oculta solo el panel de capas PostGIS (sin ocultar las capas)
  void hidePostgisLayersPanel() {
    _showPostgisLayersPanel = false;
    notifyListeners();
  }

  /// Muestra el panel de capas PostGIS
  void openPostgisLayersPanel() {
    _showPostgisLayersPanel = true;
    notifyListeners();
  }

  /// Getter para visibilidad de Colonias PostGIS
  bool get showPostgisAgebLayer => _showPostgisAgebLayer;

  /// Getter para visibilidad de Transporte PostGIS (Estaciones)
  bool get showPostgisTransporteLayer => _showPostgisTransporteLayer;
  
  /// Getter para visibilidad de Rutas PostGIS
  bool get showPostgisRutasLayer => _showPostgisRutasLayer;
  
  /// Getter para visibilidad de Líneas PostGIS
  bool get showPostgisLineasLayer => _showPostgisLineasLayer;

  /// Getter para visibilidad del panel de capas PostGIS
  bool get showPostgisLayersPanel => _showPostgisLayersPanel;

}

/// Widget para mostrar información de Colonia PostGIS en el mapa
class _PostgisAgebInfoWindow extends StatelessWidget {
  final CensoAgeb ageb;
  final CustomInfoWindowController? controller;
  
  const _PostgisAgebInfoWindow({
    required this.ageb,
    required this.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 320,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header con botón de cerrar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.location_city, color: Colors.blue[700], size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ageb.nombre ?? 'Colonia',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () {
                    controller?.hideInfoWindow?.call();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Contenido scrolleable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Ubicación
                  _buildSection('Ubicación', [
                    if (ageb.muns != null)
                      _buildInfoRow('Municipio', ageb.muns!),
                    if (ageb.numcol != null)
                      _buildInfoRow('Número de Colonia', ageb.numcol.toString()),
                    if (ageb.cp != null)
                      _buildInfoRow('Código Postal', ageb.cp.toString()),
                    if (ageb.supm2 != null)
                      _buildInfoRow('Superficie', '${(ageb.supm2! / 10000).toStringAsFixed(2)} ha'),
                  ]),
                  const Divider(height: 24),
                  // Población
                  _buildSection('Población', [
                    if (ageb.pobtot != null)
                      _buildInfoRow('Población Total', _formatNumber(ageb.pobtot!)),
                    if (ageb.pobfem != null)
                      _buildInfoRow('Población Femenina', _formatNumber(ageb.pobfem!)),
                    if (ageb.pobmas != null)
                      _buildInfoRow('Población Masculina', _formatNumber(ageb.pobmas!)),
                  ]),
                  const Divider(height: 24),
                  // Educación
                  _buildSection('Educación', [
                    if (ageb.graproes != null)
                      _buildInfoRow('Escolaridad Promedio', '${ageb.graproes!.toStringAsFixed(2)} años'),
                    if (ageb.graproesF != null)
                      _buildInfoRow('Escolaridad Femenina', '${ageb.graproesF!.toStringAsFixed(2)} años'),
                    if (ageb.graproesM != null)
                      _buildInfoRow('Escolaridad Masculina', '${ageb.graproesM!.toStringAsFixed(2)} años'),
                  ]),
                  const Divider(height: 24),
                  // Ocupación
                  _buildSection('Ocupación', [
                    if (ageb.pea != null)
                      _buildInfoRow('Población Económicamente Activa', _formatNumber(ageb.pea!)),
                    if (ageb.pocupada != null)
                      _buildInfoRow('Población Ocupada', _formatNumber(ageb.pocupada!)),
                    if (ageb.pdesocup != null)
                      _buildInfoRow('Población Desocupada', _formatNumber(ageb.pdesocup!)),
                    if (ageb.peInac != null)
                      _buildInfoRow('Población Inactiva', _formatNumber(ageb.peInac!)),
                  ]),
                  const Divider(height: 24),
                  // Vivienda
                  _buildSection('Vivienda', [
                    if (ageb.vvtot != null)
                      _buildInfoRow('Total de Viviendas', _formatNumber(ageb.vvtot!)),
                    if (ageb.tvivhab != null)
                      _buildInfoRow('Viviendas Habitadas', _formatNumber(ageb.tvivhab!)),
                    if (ageb.promOcup != null)
                      _buildInfoRow('Promedio Ocupantes', ageb.promOcup!.toStringAsFixed(2)),
                  ]),
                  const Divider(height: 24),
                  // Discapacidades
                  _buildSection('Discapacidades y Limitaciones', [
                    if (ageb.pconDisc != null)
                      _buildInfoRow('Con Discapacidad', _formatNumber(ageb.pconDisc!)),
                    if (ageb.pconLim != null)
                      _buildInfoRow('Con Limitación', _formatNumber(ageb.pconLim!)),
                    if (ageb.psindLim != null)
                      _buildInfoRow('Sin Limitación', _formatNumber(ageb.psindLim!)),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        const SizedBox(height: 8),
        ...children,
      ],
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  String _formatNumber(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (match) => '${match[1]},',
    );
  }
}

/// Widget para mostrar información de Estaciones en el mapa
class _EstacionInfoWindow extends StatelessWidget {
  final EstacionTransporte estacion;
  final CustomInfoWindowController? controller;
  
  const _EstacionInfoWindow({
    required this.estacion,
    required this.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.purple, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header fijo
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.directions_bus, color: Colors.purple[700], size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    estacion.nombre ?? 'Estación',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () {
                    controller?.hideInfoWindow?.call();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Contenido scrolleable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (estacion.sistema != null) ...[
                    _buildInfoRow('Sistema', estacion.sistema!),
                  ],
                  if (estacion.linea != null) ...[
                    _buildInfoRow('Línea', estacion.linea!),
                  ],
                  if (estacion.estructura != null) ...[
                    _buildInfoRow('Estructura', estacion.estructura!),
                  ],
                  if (estacion.estado != null) ...[
                    _buildInfoRow('Estado', estacion.estado!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar información de Rutas de Transporte en el mapa
class _RutaInfoWindow extends StatelessWidget {
  final Map<String, dynamic> data;
  final CustomInfoWindowController? controller;
  
  const _RutaInfoWindow({
    required this.data,
    required this.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    final ruta = RutaTransporte.fromJson(data);
    
    return Container(
      width: 280,
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header fijo
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.route, color: Colors.orange[700], size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    ruta.name ?? 'Ruta de Transporte',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () {
                    controller?.hideInfoWindow?.call();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Contenido scrolleable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (ruta.name != null)
                    _buildInfoRow('Nombre', ruta.name!),
                  if (ruta.folderPath != null)
                    _buildInfoRow('Carpeta', ruta.folderPath!),
                  if (ruta.shapeLeng != null)
                    _buildInfoRow('Longitud', '${ruta.shapeLeng!.toStringAsFixed(2)} m'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar información de Líneas de Transporte Masivo en el mapa
class _LineaInfoWindow extends StatelessWidget {
  final Map<String, dynamic> data;
  final CustomInfoWindowController? controller;
  
  const _LineaInfoWindow({
    required this.data,
    required this.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    final linea = LineaTransporte.fromJson(data);
    
    return Container(
      width: 280,
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.red, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header fijo
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.timeline, color: Colors.red[700], size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    linea.nombre ?? 'Línea de Transporte',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () {
                    controller?.hideInfoWindow?.call();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Contenido scrolleable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (linea.nombre != null)
                    _buildInfoRow('Nombre', linea.nombre!),
                  if (linea.tipoCo != null)
                    _buildInfoRow('Tipo', linea.tipoCo!),
                  if (linea.estado != null)
                    _buildInfoRow('Estado', linea.estado!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget para mostrar información de Google Places en el mapa
class _GooglePlaceInfoWindow extends StatelessWidget {
  final MarketplaceListing place;
  final CustomInfoWindowController? controller;
  
  const _GooglePlaceInfoWindow({
    required this.place,
    required this.controller,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      constraints: const BoxConstraints(maxHeight: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header fijo con botón cerrar
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.home, color: Colors.green[700], size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    place.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () {
                    controller?.hideInfoWindow?.call();
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          // Contenido scrolleable
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (place.price > 0)
                    _buildInfoRow('Precio', '\$${place.price.toStringAsFixed(0)}'),
                  if (place.category.isNotEmpty)
                    _buildInfoRow('Categoría', place.category),
                  if (place.description != null && place.description!.isNotEmpty)
                    _buildInfoRow('Descripción', place.description!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
