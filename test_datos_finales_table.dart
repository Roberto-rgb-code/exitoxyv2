import 'dart:io';
import 'package:postgres/postgres.dart' as pg;
import 'lib/core/config.dart' as config;

Future<void> main() async {
  print('🔍 Conectando a PostgreSQL...');
  
  final connection = pg.Connection(
    host: config.Config.postgisHost,
    port: config.Config.postgisPort,
    database: config.Config.postgisDatabase,
    username: config.Config.postgisUsername,
    password: config.Config.postgisPassword,
  );

  try {
    await connection.open();
    print('✅ Conexión establecida\n');

    // 1. Verificar que la tabla existe
    print('📋 Verificando existencia de la tabla...');
    final tableCheck = await connection.execute(
      "SELECT EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'datos_finales_geocoded');"
    );
    print('   Tabla existe: ${tableCheck[0][0]}\n');

    // 2. Obtener todas las columnas de la tabla
    print('📊 Columnas de la tabla datos_finales_geocoded:');
    final columns = await connection.execute('''
      SELECT column_name, data_type, udt_name
      FROM information_schema.columns
      WHERE table_name = 'datos_finales_geocoded'
      ORDER BY ordinal_position;
    ''');
    
    final columnNames = <String>[];
    for (final row in columns) {
      final colName = row[0] as String;
      final dataType = row[1] as String;
      final udtName = row[2] as String;
      columnNames.add(colName);
      print('   - $colName: $dataType ($udtName)');
    }
    print('');

    // 3. Verificar columnas de geometría en geometry_columns
    print('🗺️ Verificando columnas de geometría...');
    final geomColumns = await connection.execute('''
      SELECT f_table_name, f_geometry_column, coord_dimension, srid, type
      FROM geometry_columns
      WHERE f_table_name = 'datos_finales_geocoded';
    ''');
    
    if (geomColumns.isEmpty) {
      print('   ⚠️ No se encontró en geometry_columns');
    } else {
      for (final row in geomColumns) {
        print('   ✅ Columna de geometría: ${row[1]}');
        print('      Tipo: ${row[4]}, SRID: ${row[3]}, Dimensiones: ${row[2]}');
      }
    }
    print('');

    // 4. Buscar columnas que puedan contener coordenadas
    print('📍 Buscando columnas que puedan contener coordenadas...');
    for (final colName in columnNames) {
      final lower = colName.toLowerCase();
      if (lower.contains('lat') || lower.contains('lng') || lower.contains('lon') || 
          lower.contains('geom') || lower.contains('coord') || lower.contains('x') || lower.contains('y')) {
        print('   - $colName');
      }
    }
    print('');

    // 5. Obtener una muestra de datos (primeras 3 filas)
    print('📦 Muestra de datos (primeras 3 filas):');
    final sample = await connection.execute('SELECT * FROM datos_finales_geocoded LIMIT 3;');
    
    for (var i = 0; i < sample.length; i++) {
      print('\n   Fila $i:');
      for (var j = 0; j < columnNames.length && j < sample[i].length; j++) {
        final colName = columnNames[j];
        final value = sample[i][j];
        final lower = colName.toLowerCase();
        
        // Mostrar todas las columnas importantes
        if (lower.contains('lat') || lower.contains('lng') || lower.contains('lon') || 
            lower.contains('geom') || lower.contains('coord') || lower.contains('id') ||
            lower.contains('nombre') || lower.contains('precio') || lower.contains('foto')) {
          final displayValue = value?.toString() ?? 'NULL';
          final truncated = displayValue.length > 100 
              ? '${displayValue.substring(0, 100)}...' 
              : displayValue;
          print('      $colName: $truncated');
        }
      }
    }
    print('');

    // 6. Intentar extraer coordenadas de diferentes formas
    print('🔍 Intentando extraer coordenadas...');
    
    // Buscar columna de geometría
    String? geomCol;
    for (final row in geomColumns) {
      geomCol = row[1] as String;
      break;
    }
    
    if (geomCol == null) {
      // Buscar manualmente
      for (final colName in columnNames) {
        final lower = colName.toLowerCase();
        if (lower.contains('geom')) {
          geomCol = colName;
          break;
        }
      }
    }
    
    if (geomCol != null) {
      print('   Usando columna de geometría: $geomCol');
      final coordTest = await connection.execute('''
        SELECT 
          ST_Y(ST_Transform("$geomCol", 4326)) as lat,
          ST_X(ST_Transform("$geomCol", 4326)) as lng
        FROM datos_finales_geocoded
        WHERE "$geomCol" IS NOT NULL
        LIMIT 3;
      ''');
      
      if (coordTest.isEmpty) {
        print('   ⚠️ No se pudieron extraer coordenadas de la geometría');
      } else {
        print('   ✅ Coordenadas extraídas:');
        for (final row in coordTest) {
          print('      Lat: ${row[0]}, Lng: ${row[1]}');
        }
      }
    } else {
      print('   ⚠️ No se encontró columna de geometría');
      
      // Intentar con columnas lat/lng directas
      String? latCol, lngCol;
      for (final colName in columnNames) {
        final lower = colName.toLowerCase();
        if (lower == 'lat' || lower == 'latitude') latCol = colName;
        if (lower == 'lng' || lower == 'longitude' || lower == 'lon') lngCol = colName;
      }
      
      if (latCol != null && lngCol != null) {
        print('   Usando columnas directas: $latCol, $lngCol');
        final coordTest = await connection.execute('''
          SELECT "$latCol", "$lngCol"
          FROM datos_finales_geocoded
          WHERE "$latCol" IS NOT NULL AND "$lngCol" IS NOT NULL
          LIMIT 3;
        ''');
        
        if (coordTest.isEmpty) {
          print('   ⚠️ Las columnas lat/lng están vacías');
        } else {
          print('   ✅ Coordenadas encontradas:');
          for (final row in coordTest) {
            print('      Lat: ${row[0]}, Lng: ${row[1]}');
          }
        }
      }
    }

    await connection.close();
    print('\n✅ Prueba completada');
  } catch (e, stackTrace) {
    print('❌ Error: $e');
    print('Stack trace: $stackTrace');
    await connection.close();
    exit(1);
  }
}

