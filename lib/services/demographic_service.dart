import 'package:mysql_client/mysql_client.dart';
import '../core/config.dart';
import 'mysql_connector.dart';

class DemographicService {
  /// Obtiene datos demográficos agregados por código postal
  static Future<Map<String, int>> getDemographicDataByCP(String postalCode) async {
    try {
      final result = await MySQLConnector.connector.execute(
        'SELECT SUM(t) as total, SUM(m) as hombres, SUM(f) as mujeres FROM demografia WHERE cp = :cp',
        {'cp': postalCode},
      );

      if (result.rows.isNotEmpty) {
        final row = result.rows.first;
        return {
          't': int.tryParse(row.colByName('total')?.toString() ?? '0') ?? 0,
          'm': int.tryParse(row.colByName('hombres')?.toString() ?? '0') ?? 0,
          'f': int.tryParse(row.colByName('mujeres')?.toString() ?? '0') ?? 0,
        };
      }
    } catch (e) {
      print('Error obteniendo datos demográficos: $e');
    }
    
    return {'t': 0, 'm': 0, 'f': 0};
  }

  /// Obtiene datos demográficos generales para comparación
  static Future<List<Map<String, dynamic>>> getGeneralDemographicData() async {
    try {
      final result = await MySQLConnector.connector.execute(
        'SELECT * FROM demografia_general LIMIT 10',
      );

      return result.rows.map((row) => {
        'region': row.colByName('region')?.toString() ?? '',
        'total': int.tryParse(row.colByName('total')?.toString() ?? '0') ?? 0,
        'hombres': int.tryParse(row.colByName('hombres')?.toString() ?? '0') ?? 0,
        'mujeres': int.tryParse(row.colByName('mujeres')?.toString() ?? '0') ?? 0,
      }).toList();
    } catch (e) {
      print('Error obteniendo datos demográficos generales: $e');
      return [];
    }
  }

  /// Calcula estadísticas demográficas
  static Map<String, dynamic> calculateDemographicStats(Map<String, int> data) {
    final total = data['t'] ?? 0;
    final hombres = data['m'] ?? 0;
    final mujeres = data['f'] ?? 0;

    return {
      'total': total,
      'hombres': hombres,
      'mujeres': mujeres,
      'porcentaje_hombres': total > 0 ? (hombres / total * 100).toStringAsFixed(1) : '0.0',
      'porcentaje_mujeres': total > 0 ? (mujeres / total * 100).toStringAsFixed(1) : '0.0',
    };
  }
}
