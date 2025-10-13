import 'package:mysql_client/mysql_client.dart';

class MySQLConnector {
  static final connector = MySQLConnectionPool(
    host: "10.0.2.2",
    port: 3306,
    userName: "root",
    password: "kevin",
    databaseName: "kikit",
    maxConnections: 100,
  );

  static Future<List> getData(String cp) async {
    final geometry = <List>[];
    final demografic = <Map<String, dynamic>>[];
    final agebs = <String>[];

    final result = await connector.execute(
      "select * from agebs where agebs.codigoPostal=:CP",
      {'CP': cp},
    );

    for (final row in result.rows) {
      geometry.add([row.assoc()["geometry"]]);
      agebs.add(row.assoc()["idAgeb"]!);
      demografic.add({
        'f': row.assoc()["numTotalFemenino"],
        'm': row.assoc()["numTotalMasculino"],
        't': row.assoc()["numTotalHabitantes"],
      });
    }
    return [agebs, geometry, demografic];
  }

  static Future<List> getPolygonBYageb(String ageb) async {
    final geometry = <List>[];
    final result = await connector.execute(
      "select * from agebs where agebs.idAgeb=:idAgeb",
      {'idAgeb': ageb},
    );
    for (final row in result.rows) {
      geometry.add([row.assoc()["geometry"]]);
    }
    return geometry;
  }

  static Future<List<Map<String, dynamic>>> getMarkersbyCP(String cp) async {
    final out = <Map<String, dynamic>>[];
    final result = await connector.execute(
      "select * from comercios where codigoPostal=:CP",
      {'CP': cp},
    );
    for (final row in result.rows) {
      out.add(row.assoc());
    }
    return out;
  }

  static Future<List<Map<String, dynamic>>> getDemograficData() async {
    final out = <Map<String, dynamic>>[];
    final result = await connector.execute("select * from demograficos");
    for (final row in result.rows) {
      out.add(row.assoc());
    }
    return out;
  }
}
