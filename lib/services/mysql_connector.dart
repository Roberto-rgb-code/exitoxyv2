// lib/services/mysql_connector.dart
import 'package:mysql_client/mysql_client.dart';
import '../core/config.dart';

class MySQLConnector {
  static final connector = MySQLConnectionPool(
    host: Config.mysqlHost,
    port: Config.mysqlPort,
    userName: Config.mysqlUsername,
    password: Config.mysqlPassword,
    databaseName: Config.mysqlDatabase,
    maxConnections: 50,
    secure: true, // Habilitar SSL (el servidor remoto lo requiere)
  );

  /// Devuelve: [agebs(List<String>), geometry(List<dynamic>), demografic(List<Map>)]
  static Future<List> getData(String cp) async {
    final geometry = <dynamic>[];
    final demografic = <Map<String, dynamic>>[];
    final agebs = <String>[];

    print('🗄️ Ejecutando consulta MySQL para CP: $cp');
    final result = await connector.execute(
      """
      SELECT idAgeb, geometry, numTotalFemenino, numTotalMasculino, numTotalHabitantes
      FROM agebs
      WHERE codigoPostal = :CP
      """,
      {'CP': cp},
    );
    print('📋 Filas encontradas: ${result.rows.length}');

    for (final row in result.rows) {
      final m = row.assoc();
      geometry.add(m["geometry"]);
      agebs.add(m["idAgeb"] ?? '');
      demografic.add({
        'f': int.tryParse('${m["numTotalFemenino"]}') ?? 0,
        'm': int.tryParse('${m["numTotalMasculino"]}') ?? 0,
        't': int.tryParse('${m["numTotalHabitantes"]}') ?? 0,
      });
    }
    return [agebs, geometry, demografic];
  }

  static Future<List> getPolygonBYageb(String ageb) async {
    final geometry = <dynamic>[];
    final result = await connector.execute(
      "SELECT geometry FROM agebs WHERE idAgeb = :idAgeb LIMIT 1",
      {'idAgeb': ageb},
    );
    for (final row in result.rows) {
      geometry.add(row.assoc()["geometry"]);
    }
    return geometry;
  }

  /// Debe existir una tabla `comercios` con columnas lat/lon (o ajusta nombres aquí).
  static Future<List<Map<String, dynamic>>> getMarkersbyCP(String cp) async {
    final out = <Map<String, dynamic>>[];
    final result = await connector.execute(
      "SELECT * FROM comercios WHERE codigoPostal = :CP",
      {'CP': cp},
    );
    for (final row in result.rows) {
      out.add(row.assoc());
    }
    return out;
  }

  static Future<List<Map<String, dynamic>>> getDemograficData() async {
    final out = <Map<String, dynamic>>[];
    final result = await connector.execute("SELECT * FROM demograficos");
    for (final row in result.rows) {
      out.add(row.assoc());
    }
    return out;
  }
}
