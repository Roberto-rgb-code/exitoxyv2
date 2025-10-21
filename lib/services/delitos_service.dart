import 'dart:io';
import 'dart:math';
import 'package:csv/csv.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/delito_model.dart';

class DelitosService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collectionName = 'delitos';
  
  List<DelitoModel> _delitos = [];
  bool _isLoaded = false;

  List<DelitoModel> get delitos => _delitos;
  bool get isLoaded => _isLoaded;

  /// Cargar delitos desde el CSV local
  Future<void> loadDelitosFromCsv() async {
    try {
      print('🔍 Cargando delitos desde CSV...');
      
      final String csvContent = await rootBundle.loadString('assets/data/Delitoszmg.csv');
      print('📄 CSV cargado: ${csvContent.length} caracteres');
      
      final List<List<dynamic>> csvData = const CsvToListConverter().convert(csvContent);
      print('📊 CSV parseado: ${csvData.length} filas');
      
      if (csvData.isEmpty) {
        print('❌ CSV está vacío');
        return;
      }
      
      // Mostrar primera fila para debugging
      if (csvData.isNotEmpty) {
        print('📋 Primera fila (encabezados): ${csvData[0]}');
      }
      
          // El CSV parece tener solo una fila con todos los datos concatenados
          // Necesitamos dividir por líneas
          final List<String> lines = csvContent.split('\n');
          final List<List<dynamic>> dataRows = [];
          
          for (String line in lines) {
            if (line.trim().isNotEmpty) {
              // Dividir por comas, pero respetando las comillas
              final List<String> fields = _parseCsvLine(line);
              if (fields.length >= 10) {
                dataRows.add(fields);
              }
            }
          }
      print('📊 Filas de datos: ${dataRows.length}');
      
      _delitos = [];
      int processedCount = 0;
      
      for (int i = 0; i < dataRows.length; i++) {
        try {
          final row = dataRows[i];
          if (i < 3) { // Debug primeras 3 filas
            print('📋 Fila ${i + 2}: $row (${row.length} columnas)');
          }
          
          if (row.length >= 10) { // Asegurar que la fila tenga suficientes columnas
            final delito = DelitoModel.fromCsvRow(row);
            // Validar que las coordenadas sean válidas
            if (delito.x != 0.0 && delito.y != 0.0) {
              _delitos.add(delito);
              processedCount++;
              if (processedCount <= 3) { // Log solo los primeros 3 para debugging
                print('📊 Delito ${processedCount}: ${delito.delito} en ${delito.colonia}, ${delito.municipio} (${delito.x}, ${delito.y})');
              }
            } else {
              if (i < 3) { // Log solo los primeros 3 errores
                print('⚠️ Coordenadas inválidas en fila ${i + 2}: x=${delito.x}, y=${delito.y}');
              }
            }
          } else {
            if (i < 3) { // Log solo los primeros 3 errores
              print('⚠️ Fila ${i + 2} tiene solo ${row.length} columnas, necesita al menos 10');
            }
          }
        } catch (e) {
          if (i < 3) { // Log solo los primeros 3 errores
            print('⚠️ Error procesando fila ${i + 2}: $e');
          }
          // Continuar con la siguiente fila
        }
      }
      
      _isLoaded = true;
      print('✅ Delitos cargados: ${_delitos.length} registros válidos de ${dataRows.length} filas procesadas');
    } catch (e) {
      print('❌ Error cargando delitos desde CSV: $e');
      _isLoaded = false;
      _delitos = [];
    }
  }

  /// Subir delitos a Firebase Firestore
  Future<void> uploadDelitosToFirestore() async {
    if (!_isLoaded) {
      await loadDelitosFromCsv();
    }

    try {
      print('📤 Subiendo delitos a Firestore...');
      
      final batch = _firestore.batch();
      int batchCount = 0;
      const int batchSize = 500; // Firestore batch limit
      
      for (int i = 0; i < _delitos.length; i++) {
        final delito = _delitos[i];
        final docRef = _firestore.collection(_collectionName).doc();
        
        batch.set(docRef, delito.toMap());
        batchCount++;
        
        // Commit batch cuando llegue al límite
        if (batchCount >= batchSize) {
          await batch.commit();
          print('📦 Batch ${i ~/ batchSize + 1} subido: ${batchCount} delitos');
          batchCount = 0;
        }
      }
      
      // Commit el último batch si hay elementos restantes
      if (batchCount > 0) {
        await batch.commit();
        print('📦 Último batch subido: ${batchCount} delitos');
      }
      
      print('✅ Todos los delitos subidos a Firestore exitosamente');
    } catch (e) {
      print('❌ Error subiendo delitos a Firestore: $e');
    }
  }

  /// Obtener delitos desde Firestore
  Future<List<DelitoModel>> getDelitosFromFirestore() async {
    try {
      print('📥 Obteniendo delitos desde Firestore...');
      
      final QuerySnapshot snapshot = await _firestore.collection(_collectionName).get();
      
      _delitos = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return DelitoModel.fromMap(data);
      }).toList();
      
      _isLoaded = true;
      print('✅ Delitos obtenidos desde Firestore: ${_delitos.length} registros');
      
      return _delitos;
    } catch (e) {
      print('❌ Error obteniendo delitos desde Firestore: $e');
      return [];
    }
  }

  /// Obtener delitos por ubicación (radio en metros)
  List<DelitoModel> getDelitosByLocation({
    required double latitude,
    required double longitude,
    double radiusMeters = 1000,
  }) {
    if (!_isLoaded) return [];

    final List<DelitoModel> nearbyDelitos = [];
    
    for (final delito in _delitos) {
      try {
        final distance = _calculateDistance(
          latitude, longitude,
          delito.y, delito.x,
        );
        if (distance <= radiusMeters) {
          nearbyDelitos.add(delito);
        }
      } catch (e) {
        print('⚠️ Error calculando distancia para delito: $e');
        // Continuar con el siguiente delito
      }
    }
    
    print('📍 Delitos encontrados en ${radiusMeters}m: ${nearbyDelitos.length}');
    return nearbyDelitos;
  }

  /// Obtener delitos por municipio
  List<DelitoModel> getDelitosByMunicipio(String municipio) {
    if (!_isLoaded) return [];

    return _delitos.where((delito) => 
      delito.municipio.toLowerCase().contains(municipio.toLowerCase())
    ).toList();
  }

  /// Obtener delitos por tipo
  List<DelitoModel> getDelitosByType(String tipoDelito) {
    if (!_isLoaded) return [];

    return _delitos.where((delito) => 
      delito.delito.toLowerCase().contains(tipoDelito.toLowerCase())
    ).toList();
  }

  /// Obtener estadísticas de delitos por municipio
  Map<String, int> getDelitosStatsByMunicipio() {
    if (!_isLoaded) return {};

    Map<String, int> stats = {};
    for (final delito in _delitos) {
      stats[delito.municipio] = (stats[delito.municipio] ?? 0) + 1;
    }
    return stats;
  }

  /// Obtener estadísticas de delitos por tipo
  Map<String, int> getDelitosStatsByType() {
    if (!_isLoaded) return {};

    Map<String, int> stats = {};
    for (final delito in _delitos) {
      stats[delito.delito] = (stats[delito.delito] ?? 0) + 1;
    }
    return stats;
  }

  /// Calcular distancia entre dos puntos (fórmula de Haversine)
  /// Parsear una línea CSV respetando comillas
  List<String> _parseCsvLine(String line) {
    final List<String> fields = [];
    bool inQuotes = false;
    String currentField = '';
    
    for (int i = 0; i < line.length; i++) {
      final char = line[i];
      
      if (char == '"') {
        inQuotes = !inQuotes;
      } else if (char == ',' && !inQuotes) {
        fields.add(currentField.trim());
        currentField = '';
      } else {
        currentField += char;
      }
    }
    
    // Agregar el último campo
    fields.add(currentField.trim());
    
    return fields;
  }

  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Radio de la Tierra en metros
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) * cos(lat2 * pi / 180) *
        sin(dLon / 2) * sin(dLon / 2);
    
    final double c = 2 * asin(sqrt(a));
    
    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
}

// Extensión para convertir grados a radianes
extension on double {
  double toRadians() => this * (3.14159265359 / 180);
}
