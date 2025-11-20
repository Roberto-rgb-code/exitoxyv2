import '../core/config.dart';
import 'postgres_gis_service.dart';

/// Modelo de datos de propiedad (ahora desde tabla propiedades de DB GIS)
class RentaData {
  final Map<String, dynamic> data; // Todos los datos de la tabla
  final double latitude;
  final double longitude;

  RentaData({
    required this.data,
    required this.latitude,
    required this.longitude,
  });

  // Getters para compatibilidad con código existente
  int get id => data['id'] ?? data['gid'] ?? data['iddato'] ?? 0;
  String? get tipoVivienda => data['tipo_vivienda']?.toString() ?? data['tipo']?.toString();
  String? get nombre => data['nombre']?.toString() ?? data['titulo']?.toString() ?? data['descripcion']?.toString();
  String? get descripcion => data['descripcion']?.toString() ?? data['detalles']?.toString();
  double? get superficieM2 {
    final val = data['superficie_m2'] ?? data['superficie'] ?? data['m2'];
    if (val == null) return null;
    if (val is num) return val.toDouble();
    if (val is String) return double.tryParse(val);
    return null;
  }
  int? get numCuartos {
    final val = data['num_cuartos'] ?? data['cuartos'] ?? data['habitaciones'];
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }
  int? get numBanos {
    final val = data['num_banos'] ?? data['num_ba¤os'] ?? data['banos'];
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }
  int? get numCajones {
    final val = data['num_cajones'] ?? data['cajones'] ?? data['estacionamiento'];
    if (val == null) return null;
    if (val is int) return val;
    if (val is num) return val.toInt();
    if (val is String) return int.tryParse(val);
    return null;
  }
  String? get extras => data['extras']?.toString() ?? data['caracteristicas']?.toString();
  String? get codigoPostal => data['codigopostal']?.toString() ?? data['cp']?.toString() ?? data['codigo_postal']?.toString();

  Map<String, dynamic> toMap() {
    return {
      ...data,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}

/// Servicio para obtener datos de propiedades desde PostgreSQL GIS
class RentasService {
  final PostgresGisService _gisService = PostgresGisService();

  /// Cerrar conexión
  Future<void> close() async {
    await _gisService.close();
    print('🔒 Conexión PostgreSQL (Propiedades) cerrada');
  }

  /// Obtener todas las propiedades con coordenadas válidas
  Future<List<RentaData>> getAllRentas() async {
    try {
      print('🔍 Obteniendo propiedades desde tabla "propiedades" de DB GIS...');
      final propiedades = await _gisService.getAllPropiedades();
      
      print('📊 Propiedades obtenidas: ${propiedades.length}');
      final rentas = <RentaData>[];

      for (var i = 0; i < propiedades.length; i++) {
        final prop = propiedades[i];
        try {
          final lat = prop['latitude'];
          final lng = prop['longitude'];

          if (lat != null && lng != null) {
            final latDouble = lat is num ? lat.toDouble() : (lat is String ? double.tryParse(lat) : null);
            final lngDouble = lng is num ? lng.toDouble() : (lng is String ? double.tryParse(lng) : null);

            if (latDouble != null && lngDouble != null) {
              // Remover campos calculados del mapa de datos
              final data = Map<String, dynamic>.from(prop);
              data.remove('latitude');
              data.remove('longitude');
              data.remove('geom_json');

              final renta = RentaData(
                data: data,
                latitude: latDouble,
                longitude: lngDouble,
              );
              rentas.add(renta);
              
              if (i < 3) {
                print('   ✅ Propiedad ${i + 1}: ${renta.nombre ?? 'Sin nombre'} (${renta.latitude}, ${renta.longitude})');
              }
            } else {
              print('   ⚠️ Coordenadas inválidas para propiedad $i');
            }
          } else {
            print('   ⚠️ Coordenadas nulas para propiedad $i');
          }
        } catch (e, stackTrace) {
          print('⚠️ Error procesando propiedad $i: $e');
          print('   Stack trace: $stackTrace');
        }
      }

      print('✅ Total de ${rentas.length} propiedades procesadas');
      return rentas;
    } catch (e, stackTrace) {
      print('❌ Error obteniendo propiedades: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Obtener propiedades dentro de un área específica
  Future<List<RentaData>> getRentasInBounds({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
  }) async {
    try {
      final propiedades = await _gisService.getPropiedadesInBounds(
        minLat: minLat,
        minLng: minLng,
        maxLat: maxLat,
        maxLng: maxLng,
      );

      final rentas = <RentaData>[];

      for (final prop in propiedades) {
        try {
          final lat = prop['latitude'];
          final lng = prop['longitude'];

          if (lat != null && lng != null) {
            final latDouble = lat is num ? lat.toDouble() : (lat is String ? double.tryParse(lat) : null);
            final lngDouble = lng is num ? lng.toDouble() : (lng is String ? double.tryParse(lng) : null);

            if (latDouble != null && lngDouble != null) {
              final data = Map<String, dynamic>.from(prop);
              data.remove('latitude');
              data.remove('longitude');
              data.remove('geom_json');

              rentas.add(RentaData(
                data: data,
                latitude: latDouble,
                longitude: lngDouble,
              ));
            }
          }
        } catch (e) {
          print('⚠️ Error procesando propiedad: $e');
        }
      }

      return rentas;
    } catch (e) {
      print('❌ Error obteniendo propiedades en área: $e');
      rethrow;
    }
  }
}

