import 'package:postgres/postgres.dart' as pg;
import '../core/config.dart';

/// Modelo de datos de renta
class RentaData {
  final int id;
  final String? tipoVivienda;
  final double latitude;
  final double longitude;
  final String? nombre;
  final String? descripcion;
  final double? superficieM2;
  final int? numCuartos;
  final int? numBanos;
  final int? numCajones;
  final String? extras;
  final String? codigoPostal;

  RentaData({
    required this.id,
    this.tipoVivienda,
    required this.latitude,
    required this.longitude,
    this.nombre,
    this.descripcion,
    this.superficieM2,
    this.numCuartos,
    this.numBanos,
    this.numCajones,
    this.extras,
    this.codigoPostal,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tipo_vivienda': tipoVivienda,
      'latitude': latitude,
      'longitude': longitude,
      'nombre': nombre,
      'descripcion': descripcion,
      'superficie_m2': superficieM2,
      'num_cuartos': numCuartos,
      'num_banos': numBanos,
      'num_cajones': numCajones,
      'extras': extras,
      'codigo_postal': codigoPostal,
    };
  }
}

/// Servicio para obtener datos de rentas desde PostgreSQL
class RentasService {
  pg.Connection? _connection;

  /// Obtener conexión a la base de datos
  Future<pg.Connection> getConnection() async {
    if (_connection != null) {
      return _connection!;
    }

    _connection = await pg.Connection.open(
      pg.Endpoint(
        host: Config.postgresHost,
        port: Config.postgresPort,
        database: Config.postgresDatabase,
        username: Config.postgresUsername,
        password: Config.postgresPassword,
      ),
      settings: pg.ConnectionSettings(
        sslMode: pg.SslMode.require,
      ),
    );

    print('✅ Conexión a PostgreSQL (Rentas) establecida');
    return _connection!;
  }

  /// Cerrar conexión
  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      print('🔒 Conexión PostgreSQL (Rentas) cerrada');
    }
  }

  /// Obtener todas las rentas con coordenadas válidas
  Future<List<RentaData>> getAllRentas() async {
    final conn = await getConnection();

    try {
      print('🔍 Ejecutando consulta para obtener rentas...');
      final result = await conn.execute('''
        SELECT 
          iddato,
          tipo_vivienda,
          ST_Y(coordenadas::geometry) as latitude,
          ST_X(coordenadas::geometry) as longitude,
          nombre,
          descripcion,
          superficie_m2,
          num_cuartos,
          "num_ba¤os",
          num_cajones,
          extras,
          codigopostal
        FROM comercios
        WHERE coordenadas IS NOT NULL;
      ''');

      print('📊 Filas obtenidas de la consulta: ${result.length}');
      final rentas = <RentaData>[];

      for (var i = 0; i < result.length; i++) {
        final row = result[i];
        try {
          print('📝 Procesando fila $i: iddato=${row[0]}, nombre=${row[4]}');
          
          final lat = (row[2] as num?)?.toDouble();
          final lng = (row[3] as num?)?.toDouble();

          print('   Coordenadas: lat=$lat, lng=$lng');

          if (lat != null && lng != null) {
            // Función helper para convertir valores a numéricos de forma segura
            double? parseDouble(dynamic value) {
              if (value == null) return null;
              if (value is num) return value.toDouble();
              if (value is String) {
                final parsed = double.tryParse(value);
                return parsed;
              }
              return null;
            }

            int? parseInt(dynamic value) {
              if (value == null) return null;
              if (value is int) return value;
              if (value is num) return value.toInt();
              if (value is String) {
                final parsed = int.tryParse(value);
                return parsed;
              }
              return null;
            }

            final renta = RentaData(
              id: row[0] as int,
              tipoVivienda: row[1]?.toString(),
              latitude: lat,
              longitude: lng,
              nombre: row[4]?.toString(),
              descripcion: row[5]?.toString(),
              superficieM2: parseDouble(row[6]),
              numCuartos: parseInt(row[7]),
              numBanos: parseInt(row[8]),
              numCajones: parseInt(row[9]),
              extras: row[10]?.toString(),
              codigoPostal: row[11]?.toString(),
            );
            rentas.add(renta);
            print('   ✅ Renta agregada: ${renta.nombre} (${renta.latitude}, ${renta.longitude})');
          } else {
            print('   ⚠️ Coordenadas nulas o inválidas para fila $i');
          }
        } catch (e, stackTrace) {
          print('⚠️ Error procesando registro de renta $i: $e');
          print('   Stack trace: $stackTrace');
        }
      }

      print('✅ Total de ${rentas.length} rentas obtenidas y procesadas');
      return rentas;
    } catch (e, stackTrace) {
      print('❌ Error obteniendo rentas: $e');
      print('   Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Obtener rentas dentro de un área específica
  Future<List<RentaData>> getRentasInBounds({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
  }) async {
    final conn = await getConnection();

    try {
      final result = await conn.execute('''
        SELECT 
          iddato,
          tipo_vivienda,
          ST_Y(coordenadas::geometry) as latitude,
          ST_X(coordenadas::geometry) as longitude,
          nombre,
          descripcion,
          superficie_m2,
          num_cuartos,
          "num_ba¤os",
          num_cajones,
          extras,
          codigopostal
        FROM comercios
        WHERE coordenadas IS NOT NULL
        AND ST_Y(coordenadas::geometry) BETWEEN \$1 AND \$2
        AND ST_X(coordenadas::geometry) BETWEEN \$3 AND \$4;
      ''', parameters: [minLat, maxLat, minLng, maxLng]);

      final rentas = <RentaData>[];

      // Función helper para convertir valores a numéricos de forma segura
      double? parseDouble(dynamic value) {
        if (value == null) return null;
        if (value is num) return value.toDouble();
        if (value is String) {
          final parsed = double.tryParse(value);
          return parsed;
        }
        return null;
      }

      int? parseInt(dynamic value) {
        if (value == null) return null;
        if (value is int) return value;
        if (value is num) return value.toInt();
        if (value is String) {
          final parsed = int.tryParse(value);
          return parsed;
        }
        return null;
      }

      for (final row in result) {
        try {
          final lat = (row[2] as num?)?.toDouble();
          final lng = (row[3] as num?)?.toDouble();

          if (lat != null && lng != null) {
            rentas.add(RentaData(
              id: row[0] as int,
              tipoVivienda: row[1]?.toString(),
              latitude: lat,
              longitude: lng,
              nombre: row[4]?.toString(),
              descripcion: row[5]?.toString(),
              superficieM2: parseDouble(row[6]),
              numCuartos: parseInt(row[7]),
              numBanos: parseInt(row[8]),
              numCajones: parseInt(row[9]),
              extras: row[10]?.toString(),
              codigoPostal: row[11]?.toString(),
            ));
          }
        } catch (e) {
          print('⚠️ Error procesando registro de renta: $e');
        }
      }

      return rentas;
    } catch (e) {
      print('❌ Error obteniendo rentas en área: $e');
      rethrow;
    }
  }
}

