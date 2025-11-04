import 'package:postgres/postgres.dart' as pg;
import '../core/config.dart';

/// Servicio para conectar con PostgreSQL y obtener capas espaciales
class PostgresGisService {
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

    print('✅ Conexión a PostgreSQL establecida');
    return _connection!;
  }

  /// Cerrar conexión
  Future<void> close() async {
    if (_connection != null) {
      await _connection!.close();
      _connection = null;
      print('🔒 Conexión PostgreSQL cerrada');
    }
  }

  /// Listar todas las tablas/capas espaciales en la base de datos
  Future<List<Map<String, dynamic>>> listSpatialTables() async {
    final conn = await getConnection();
    
    final result = await conn.execute('''
      SELECT 
        table_name,
        table_type
      FROM information_schema.tables
      WHERE table_schema = 'public'
      ORDER BY table_name;
    ''');

    final tables = <Map<String, dynamic>>[];
    for (final row in result) {
      tables.add({
        'name': row[0]?.toString() ?? '',
        'type': row[1]?.toString() ?? '',
      });
    }

    return tables;
  }

  /// Obtener información de columnas de una tabla
  Future<List<Map<String, dynamic>>> getTableColumns(String tableName) async {
    final conn = await getConnection();
    
    final result = await conn.execute(
      '''
      SELECT 
        column_name,
        data_type,
        is_nullable,
        column_default
      FROM information_schema.columns
      WHERE table_schema = 'public'
      AND table_name = \$1
      ORDER BY ordinal_position;
      ''',
      parameters: [tableName],
    );

    final columns = <Map<String, dynamic>>[];
    for (final row in result) {
      columns.add({
        'name': row[0]?.toString() ?? '',
        'type': row[1]?.toString() ?? '',
        'nullable': row[2]?.toString() ?? '',
        'default': row[3]?.toString(),
      });
    }

    return columns;
  }

  /// Verificar si una tabla tiene geometrías espaciales
  Future<bool> hasGeometryColumn(String tableName) async {
    final conn = await getConnection();
    
    try {
      final result = await conn.execute(
        '''
        SELECT COUNT(*) 
        FROM geometry_columns 
        WHERE f_table_name = \$1;
        ''',
        parameters: [tableName],
      );

      return (result.first[0] as int) > 0;
    } catch (e) {
      // Si no existe geometry_columns, intentar otra forma
      final columns = await getTableColumns(tableName);
      return columns.any((col) => 
        col['type'].toString().toLowerCase().contains('geometry') ||
        col['name'].toString().toLowerCase().contains('geom')
      );
    }
  }

  /// Obtener información de geometría de una tabla
  Future<Map<String, dynamic>?> getGeometryInfo(String tableName) async {
    final conn = await getConnection();
    
    try {
      final result = await conn.execute(
        '''
        SELECT 
          f_geometry_column,
          type,
          coord_dimension,
          srid
        FROM geometry_columns 
        WHERE f_table_name = \$1
        LIMIT 1;
        ''',
        parameters: [tableName],
      );

      if (result.isEmpty) return null;

      final row = result.first;
      return {
        'column': row[0]?.toString() ?? '',
        'type': row[1]?.toString() ?? '',
        'dimension': row[2]?.toString() ?? '',
        'srid': row[3]?.toString() ?? '',
      };
    } catch (e) {
      print('⚠️ No se pudo obtener info de geometría: $e');
      return null;
    }
  }

  /// Obtener una muestra de datos de una tabla (limitada)
  Future<List<Map<String, dynamic>>> getTableSample(
    String tableName, {
    int limit = 10,
    String? geometryColumn,
  }) async {
    final conn = await getConnection();
    
    // Primero obtener los nombres de las columnas
    final columns = await getTableColumns(tableName);
    final columnNames = columns.map((col) => col['name'] as String).toList();
    if (geometryColumn != null && !columnNames.contains('geom_json')) {
      columnNames.add('geom_json');
    }
    
    // Si tiene geometría, convertirla a GeoJSON
    String selectClause = '*';
    if (geometryColumn != null) {
      selectClause = '''
        *, 
        ST_AsGeoJSON("$geometryColumn") as geom_json
      ''';
    }

    final result = await conn.execute('''
      SELECT $selectClause
      FROM "$tableName"
      LIMIT \$1;
    ''', parameters: [limit]);

    final rows = <Map<String, dynamic>>[];
    for (final row in result) {
      final map = <String, dynamic>{};
      for (var i = 0; i < row.length; i++) {
        final column = i < columnNames.length ? columnNames[i] : 'col_$i';
        var value = row[i];
        map[column] = value;
      }
      rows.add(map);
    }

    return rows;
  }

  /// Contar registros en una tabla
  Future<int> countRecords(String tableName) async {
    final conn = await getConnection();
    
    final result = await conn.execute('''
      SELECT COUNT(*) FROM "$tableName";
    ''');

    return (result.first[0] as int?) ?? 0;
  }

  /// Analizar esquema completo de una tabla (información detallada)
  Future<Map<String, dynamic>> analyzeTableSchema(String tableName) async {
    final conn = await getConnection();
    
    final schema = <String, dynamic>{
      'name': tableName,
      'columns': [],
      'geometry': null,
      'indexes': [],
      'constraints': [],
      'sample_data': [],
    };
    
    try {
      // Obtener columnas detalladas
      final columnsResult = await conn.execute('''
        SELECT 
          column_name,
          data_type,
          udt_name,
          character_maximum_length,
          is_nullable,
          column_default,
          ordinal_position
        FROM information_schema.columns
        WHERE table_schema = 'public'
        AND table_name = \$1
        ORDER BY ordinal_position;
      ''', parameters: [tableName]);

      final columns = <Map<String, dynamic>>[];
      String? geometryColumn;
      
      for (final row in columnsResult) {
        final colInfo = {
          'name': row[0]?.toString() ?? '',
          'type': row[1]?.toString() ?? '',
          'udt_name': row[2]?.toString() ?? '',
          'max_length': row[3],
          'nullable': row[4]?.toString() == 'YES',
          'default': row[5]?.toString(),
          'position': row[6],
        };
        columns.add(colInfo);
        
        // Detectar columnas de geometría
        if (row[2]?.toString().toLowerCase().contains('geometry') == true ||
            row[0]?.toString().toLowerCase().contains('geom') == true) {
          geometryColumn = row[0]?.toString();
        }
      }
      
      schema['columns'] = columns;
      
      // Información de geometría si existe
      if (geometryColumn != null) {
        try {
          final geomResult = await conn.execute('''
            SELECT 
              f_geometry_column,
              type,
              coord_dimension,
              srid
            FROM geometry_columns 
            WHERE f_table_name = \$1 AND f_geometry_column = \$2
            LIMIT 1;
          ''', parameters: [tableName, geometryColumn]);
          
          if (geomResult.isNotEmpty) {
            final row = geomResult.first;
            schema['geometry'] = {
              'column': row[0]?.toString() ?? '',
              'type': row[1]?.toString() ?? '',
              'dimension': row[2]?.toString() ?? '',
              'srid': row[3]?.toString() ?? '',
            };
          }
        } catch (e) {
          // geometry_columns puede no estar disponible
        }
      }
      
      // Obtener índices
      try {
        final indexesResult = await conn.execute('''
          SELECT 
            indexname,
            indexdef
          FROM pg_indexes
          WHERE schemaname = 'public'
          AND tablename = \$1;
        ''', parameters: [tableName]);
        
        final indexes = <Map<String, dynamic>>[];
        for (final row in indexesResult) {
          indexes.add({
            'name': row[0]?.toString() ?? '',
            'definition': row[1]?.toString() ?? '',
          });
        }
        schema['indexes'] = indexes;
      } catch (e) {
        // Ignorar errores de índices
      }
      
      // Obtener constraints (primary keys, foreign keys, etc)
      try {
        final constraintsResult = await conn.execute('''
          SELECT 
            constraint_name,
            constraint_type
          FROM information_schema.table_constraints
          WHERE table_schema = 'public'
          AND table_name = \$1;
        ''', parameters: [tableName]);
        
        final constraints = <Map<String, dynamic>>[];
        for (final row in constraintsResult) {
          constraints.add({
            'name': row[0]?.toString() ?? '',
            'type': row[1]?.toString() ?? '',
          });
        }
        schema['constraints'] = constraints;
      } catch (e) {
        // Ignorar errores de constraints
      }
      
      // Obtener muestra de datos (3 registros)
      try {
        String query = 'SELECT * FROM "$tableName" LIMIT 3';
        final geomCol = schema['geometry'] != null ? schema['geometry']['column'] as String? : null;
        if (geomCol != null) {
          query = '''
            SELECT 
              *,
              ST_AsGeoJSON("$geomCol") as geom_json
            FROM "$tableName"
            LIMIT 3
          ''';
        }
        
        final sampleResult = await conn.execute(query);
        final sample = <Map<String, dynamic>>[];
        final columnNamesList = columns.map((c) => c['name'] as String).toList();
        if (geomCol != null && !columnNamesList.contains('geom_json')) {
          columnNamesList.add('geom_json');
        }
        
        for (final row in sampleResult) {
          final rowMap = <String, dynamic>{};
          for (var i = 0; i < row.length; i++) {
            final colName = i < columnNamesList.length ? columnNamesList[i] : 'col_$i';
            rowMap[colName] = row[i];
          }
          sample.add(rowMap);
        }
        
        schema['sample_data'] = sample;
      } catch (e) {
        print('⚠️ Error obteniendo muestra: $e');
      }
      
    } catch (e) {
      print('❌ Error analizando esquema: $e');
    }
    
    return schema;
  }

  /// Analizar todas las capas espaciales
  Future<List<Map<String, dynamic>>> analyzeAllLayers() async {
    final tables = await listSpatialTables();
    final layers = <Map<String, dynamic>>[];
    
    for (var table in tables) {
      final tableName = table['name'] as String;
      print('🔍 Analizando capa: $tableName...');
      
      final schema = await analyzeTableSchema(tableName);
      final count = await countRecords(tableName);
      schema['record_count'] = count;
      
      layers.add(schema);
    }
    
    return layers;
  }

  /// Obtener geometrías en un área específica (bounding box)
  Future<List<Map<String, dynamic>>> getGeometriesInBounds({
    required String tableName,
    required String geometryColumn,
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    int limit = 100,
  }) async {
    final conn = await getConnection();
    
    // Primero obtener los nombres de las columnas
    final columns = await getTableColumns(tableName);
    final columnNames = columns.map((col) => col['name'] as String).toList();
    columnNames.add('geom_json');
    
    final result = await conn.execute(
      '''
      SELECT 
        *,
        ST_AsGeoJSON("$geometryColumn") as geom_json
      FROM "$tableName"
      WHERE ST_Intersects(
        "$geometryColumn",
        ST_MakeEnvelope(\$1, \$2, \$3, \$4, 4326)
      )
      LIMIT \$5;
      ''',
      parameters: [minLng, minLat, maxLng, maxLat, limit],
    );

    final rows = <Map<String, dynamic>>[];
    for (final row in result) {
      final map = <String, dynamic>{};
      for (var i = 0; i < row.length; i++) {
        final column = i < columnNames.length ? columnNames[i] : 'col_$i';
        map[column] = row[i];
      }
      rows.add(map);
    }

    return rows;
  }

  // ============================================================
  // MÉTODOS ESPECÍFICOS POR CAPA
  // ============================================================

  /// Obtener Colonias en un área
  Future<List<Map<String, dynamic>>> getAgebInBounds({
    required double minLat,
    required double minLng,
    required double maxLat,
    required double maxLng,
    int limit = 100,
  }) async {
    final conn = await getConnection();
    
    // Obtener columnas primero
    final columns = await getTableColumns('ISDCOL2020_2021F');
    final columnNames = columns.map((col) => col['name'] as String).toList();
    columnNames.add('geom_json');
    
    final result = await conn.execute(
      '''
      SELECT 
        *,
        ST_AsGeoJSON(ST_Transform(geom, 4326)) as geom_json
      FROM "ISDCOL2020_2021F"
      WHERE ST_Intersects(
        ST_Transform(geom, 4326),
        ST_MakeEnvelope(\$1, \$2, \$3, \$4, 4326)
      )
      LIMIT \$5;
      ''',
      parameters: [minLng, minLat, maxLng, maxLat, limit],
    );

    final rows = <Map<String, dynamic>>[];
    for (final row in result) {
      final map = <String, dynamic>{};
      for (var i = 0; i < row.length; i++) {
        final column = i < columnNames.length ? columnNames[i] : 'col_$i';
        map[column] = row[i];
      }
      rows.add(map);
    }

    return rows;
  }

  /// Obtener TODAS las Colonias sin límite ni filtro de bounds
  Future<List<Map<String, dynamic>>> getAllAgeb() async {
    final conn = await getConnection();
    
    // Obtener columnas primero
    final columns = await getTableColumns('ISDCOL2020_2021F');
    final columnNames = columns.map((col) => col['name'] as String).toList();
    columnNames.add('geom_json');
    
    final result = await conn.execute(
      '''
      SELECT 
        *,
        ST_AsGeoJSON(ST_Transform(geom, 4326)) as geom_json
      FROM "ISDCOL2020_2021F";
      ''',
    );

    final rows = <Map<String, dynamic>>[];
    for (final row in result) {
      final map = <String, dynamic>{};
      for (var i = 0; i < row.length; i++) {
        final column = i < columnNames.length ? columnNames[i] : 'col_$i';
        map[column] = row[i];
      }
      rows.add(map);
    }

    return rows;
  }

  /// Obtener todas las rutas de transporte
  Future<List<Map<String, dynamic>>> getRutasTransporte({
    int limit = 546,
  }) async {
    final conn = await getConnection();
    
    final columns = await getTableColumns('ZMG_Rutas-Mov');
    final columnNames = columns.map((col) => col['name'] as String).toList();
    columnNames.add('geom_json');
    
    final result = await conn.execute(
      '''
      SELECT *, ST_AsGeoJSON(ST_Transform(geom, 4326)) as geom_json
      FROM "ZMG_Rutas-Mov"
      LIMIT \$1;
      ''',
      parameters: [limit],
    );

    final rows = <Map<String, dynamic>>[];
    for (final row in result) {
      final map = <String, dynamic>{};
      for (var i = 0; i < row.length; i++) {
        final column = i < columnNames.length ? columnNames[i] : 'col_$i';
        map[column] = row[i];
      }
      rows.add(map);
    }

    return rows;
  }

  /// Obtener todas las estaciones de transporte
  Future<List<Map<String, dynamic>>> getEstacionesTransporte({
    int limit = 115,
  }) async {
    final conn = await getConnection();
    
    final columns = await getTableColumns('estaciones_de_transporte_masivo');
    final columnNames = columns.map((col) => col['name'] as String).toList();
    columnNames.add('geom_json');
    
    final result = await conn.execute(
      '''
      SELECT *, ST_AsGeoJSON(ST_Transform(geom, 4326)) as geom_json
      FROM estaciones_de_transporte_masivo
      LIMIT \$1;
      ''',
      parameters: [limit],
    );

    final rows = <Map<String, dynamic>>[];
    for (final row in result) {
      final map = <String, dynamic>{};
      for (var i = 0; i < row.length; i++) {
        final column = i < columnNames.length ? columnNames[i] : 'col_$i';
        map[column] = row[i];
      }
      rows.add(map);
    }

    return rows;
  }

  /// Obtener líneas de transporte masivo y alimentador
  Future<List<Map<String, dynamic>>> getLineasTransporte({
    int limit = 38,
  }) async {
    final conn = await getConnection();
    
    final columns = await getTableColumns('vwtransporte_masivo_y_alimentador_2022');
    final columnNames = columns.map((col) => col['name'] as String).toList();
    columnNames.add('geom_json');
    
    final result = await conn.execute(
      '''
      SELECT *, ST_AsGeoJSON(ST_Transform(geom, 4326)) as geom_json
      FROM vwtransporte_masivo_y_alimentador_2022
      LIMIT \$1;
      ''',
      parameters: [limit],
    );

    final rows = <Map<String, dynamic>>[];
    for (final row in result) {
      final map = <String, dynamic>{};
      for (var i = 0; i < row.length; i++) {
        final column = i < columnNames.length ? columnNames[i] : 'col_$i';
        map[column] = row[i];
      }
      rows.add(map);
    }

    return rows;
  }
}

