// lib/features/explore/explore_controller.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

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
  final Map<MarkerId, Marker> _markers = {};
  Set<Marker> allMarkers() {
    final markers = _markers.values.toSet();
    print('🗺️ allMarkers() llamado: ${markers.length} marcadores');
    print('🗺️ Marcadores DENUE: ${_markers.keys.where((key) => key.value.startsWith('denue_')).length}');
    print('🗺️ Marcadores Delitos: ${_markers.keys.where((key) => key.value.startsWith('delito_')).length}');
    return markers;
  }

  bool myLocationEnabled = false;

  String? activeCP;
  Map<String, int>? demographyAgg; // {'t','m','f'}
  
  // Variables para análisis de concentración
  bool showConcentrationLayer = false;
  ConcentrationResult? currentConcentration;
  String? currentActivity;
  
  // Variables para recomendaciones
  List<Recommendation> recommendations = [];

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

  ExploreController() {
    ensureLocationReady();
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

      // Crear marcadores comerciales
      final markersService = MarkersCommercialService(commercialData);
      final markers = markersService.createCommercialMarkers();

      // Agregar marcadores al mapa
      for (int i = 0; i < commercialData.length; i++) {
        final data = commercialData[i];
        final markerId = MarkerId('commercial_$i');
        final marker = Marker(
          markerId: markerId,
          position: LatLng(
            double.parse(data['lat'] ?? '0'),
            double.parse(data['lon'] ?? '0'),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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
    
    // Crear un marcador más visible como en el código que funciona
    final marker = Marker(
      markerId: id,
      position: p,
      anchor: const Offset(0.5, 1),
      consumeTapEvents: false,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
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
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
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

  /// Analiza la concentración del mercado para una actividad específica
  Future<void> analyzeConcentration(String activity) async {
    if (lastPoint == null || activeCP == null) {
      throw Exception('Selecciona una zona primero (tap en el mapa o busca una dirección)');
    }

    currentActivity = activity;
    print('🔍 Analizando concentración para: $activity en CP: $activeCP');
    
    // Verificar cache
    final cached = CacheService.get(activity, activeCP!);
    if (cached != null) {
      print('✅ Usando datos en cache');
      currentConcentration = cached;
      showConcentrationLayer = true;
      
      // Generar recomendaciones aunque sea del cache
      await _generateRecommendations();
      
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
    
    if (lastPoint == null) {
      print('⚠️ No hay ubicación para mostrar marcadores DENUE');
      return;
    }
    
    print('🎯 INICIANDO CREACIÓN DE MARCADORES DENUE...');

    try {
      print('🔍 Cargando marcadores DENUE para: "$activity"');
      
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
      _markers.removeWhere((key, marker) => key.value.startsWith('denue_'));

      // Determinar color basado en concentración
      double markerHue = BitmapDescriptor.hueBlue; // Default azul
      if (currentConcentration != null) {
        // Colores según nivel de concentración
        if (currentConcentration!.hhi < 1500) {
          markerHue = BitmapDescriptor.hueGreen; // Verde - Baja concentración
        } else if (currentConcentration!.hhi < 2500) {
          markerHue = BitmapDescriptor.hueYellow; // Amarillo - Moderada
        } else if (currentConcentration!.hhi < 3500) {
          markerHue = BitmapDescriptor.hueOrange; // Naranja - Alta
        } else {
          markerHue = BitmapDescriptor.hueRed; // Rojo - Muy alta
        }
        print('🎨 Color de marcadores: HHI=${currentConcentration!.hhi} -> Hue=$markerHue');
      }

      // Crear marcadores
      print('🎨 Creando ${entries.length} marcadores DENUE...');
      for (int i = 0; i < entries.length; i++) {
        final entry = entries[i];
        final markerId = MarkerId('denue_$i');
        
        if (i < 3) { // Debug primeros 3 marcadores
          print('📍 Marcador $i: ${entry.name} en ${entry.position}');
        }
        
        final marker = Marker(
          markerId: markerId,
          position: entry.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(markerHue),
          infoWindow: InfoWindow(
            title: entry.name,
            snippet: 'Tap para más información',
          ),
          onTap: () => _showDenueInfoWindow(entry),
        );

        _markers[markerId] = marker;
      }
      
      print('🎯 MARCADORES DENUE AGREGADOS AL MAPA: ${_markers.length}');

      print('✅ DENUE: ${entries.length} marcadores agregados al mapa');
      print('📊 Total de marcadores en el mapa: ${_markers.length}');
      print('📊 Marcadores DENUE: ${_markers.keys.where((key) => key.value.startsWith('denue_')).length}');
      
      // Debugging: mostrar algunos marcadores
      if (entries.isNotEmpty) {
        print('📍 Primer marcador: ${entries[0].name} en ${entries[0].position}');
        if (entries.length > 1) {
          print('📍 Segundo marcador: ${entries[1].name} en ${entries[1].position}');
        }
      }
      
      notifyListeners();
    } catch (e) {
      print('❌ Error mostrando marcadores DENUE: $e');
      rethrow;
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

      // Crear marcadores de delitos con icono distintivo (rojo violeta)
      print('🔴 Creando ${delitosToShow.length} marcadores de delitos...');
      for (int i = 0; i < delitosToShow.length; i++) {
        final delito = delitosToShow[i];
        final markerId = MarkerId('delito_$i');

        if (i < 3) { // Debug primeros 3 marcadores
          print('🔴 Marcador delito $i: ${delito.delito} en (${delito.y}, ${delito.x})');
        }

        final marker = Marker(
          markerId: markerId,
          position: LatLng(delito.y, delito.x), // y=latitud, x=longitud
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          alpha: 0.8, // Transparencia para distinguir de otros marcadores
          infoWindow: InfoWindow(
            title: '⚠️ ${delito.delito}',
            snippet: 'Tap para detalles',
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
      ),
      LatLng(delito.y, delito.x),
    );
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

  /// Oculta la capa de concentración
  void hideConcentrationLayer() {
    showConcentrationLayer = false;
    currentConcentration = null;
    currentActivity = null;
    recommendations.clear();
    _markers.removeWhere((key, marker) => key.value.startsWith('denue_'));
    notifyListeners();
  }

}
