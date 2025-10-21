import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/search_record_model.dart';

class SearchHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static const String _collectionName = 'search_history';

  /// Guardar una búsqueda en Firestore
  Future<String> saveSearch({
    required double latitude,
    required double longitude,
    required String locationName,
    Map<String, dynamic>? searchFilters,
    List<String>? recommendedAreas,
    Map<String, dynamic>? crimeData,
    Map<String, dynamic>? placesData,
    Map<String, dynamic>? streetViewData,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final docRef = _firestore.collection(_collectionName).doc();
      
      final searchRecord = SearchRecordModel(
        id: docRef.id,
        userId: user.uid,
        latitude: latitude,
        longitude: longitude,
        locationName: locationName,
        timestamp: DateTime.now(),
        searchFilters: searchFilters,
        recommendedAreas: recommendedAreas,
        crimeData: crimeData,
        placesData: placesData,
        streetViewData: streetViewData,
      );

      await docRef.set(searchRecord.toFirestore());
      
      print('✅ Búsqueda guardada: $locationName');
      return docRef.id;
    } catch (e) {
      print('❌ Error guardando búsqueda: $e');
      rethrow;
    }
  }

  /// Obtener historial de búsquedas del usuario actual
  Future<List<SearchRecordModel>> getUserSearchHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return [];
      }

      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .orderBy('timestamp', descending: true)
          .limit(50) // Limitar a las últimas 50 búsquedas
          .get();

      return snapshot.docs.map((doc) => 
        SearchRecordModel.fromFirestore(doc)
      ).toList();
    } catch (e) {
      print('❌ Error obteniendo historial de búsquedas: $e');
      return [];
    }
  }

  /// Obtener búsquedas por ubicación (para análisis de patrones)
  Future<List<SearchRecordModel>> getSearchesByLocation({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .get();

      final List<SearchRecordModel> searches = snapshot.docs.map((doc) => 
        SearchRecordModel.fromFirestore(doc)
      ).toList();

      // Filtrar por distancia
      return searches.where((search) {
        final distance = _calculateDistance(
          latitude, longitude,
          search.latitude, search.longitude,
        );
        return distance <= radiusKm;
      }).toList();
    } catch (e) {
      print('❌ Error obteniendo búsquedas por ubicación: $e');
      return [];
    }
  }

  /// Obtener estadísticas de búsquedas
  Future<Map<String, dynamic>> getSearchStats() async {
    try {
      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .get();

      final List<SearchRecordModel> searches = snapshot.docs.map((doc) => 
        SearchRecordModel.fromFirestore(doc)
      ).toList();

      // Estadísticas básicas
      final totalSearches = searches.length;
      final uniqueLocations = searches.map((s) => s.locationName).toSet().length;
      
      // Municipios más buscados
      final Map<String, int> municipioCounts = {};
      for (final search in searches) {
        final municipio = search.locationName.split(',').last.trim();
        municipioCounts[municipio] = (municipioCounts[municipio] ?? 0) + 1;
      }

      // Búsquedas por día de la semana
      final Map<String, int> dayOfWeekCounts = {};
      for (final search in searches) {
        final dayName = _getDayName(search.timestamp.weekday);
        dayOfWeekCounts[dayName] = (dayOfWeekCounts[dayName] ?? 0) + 1;
      }

      return {
        'totalSearches': totalSearches,
        'uniqueLocations': uniqueLocations,
        'topMunicipios': municipioCounts,
        'searchesByDay': dayOfWeekCounts,
        'lastUpdated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      print('❌ Error obteniendo estadísticas de búsquedas: $e');
      return {};
    }
  }

  /// Eliminar una búsqueda específica
  Future<void> deleteSearch(String searchId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Verificar que la búsqueda pertenece al usuario actual
      final doc = await _firestore.collection(_collectionName).doc(searchId).get();
      if (!doc.exists) {
        throw Exception('Búsqueda no encontrada');
      }

      final data = doc.data() as Map<String, dynamic>;
      if (data['userId'] != user.uid) {
        throw Exception('No tienes permisos para eliminar esta búsqueda');
      }

      await _firestore.collection(_collectionName).doc(searchId).delete();
      print('✅ Búsqueda eliminada: $searchId');
    } catch (e) {
      print('❌ Error eliminando búsqueda: $e');
      rethrow;
    }
  }

  /// Limpiar historial de búsquedas del usuario
  Future<void> clearUserSearchHistory() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final QuerySnapshot snapshot = await _firestore
          .collection(_collectionName)
          .where('userId', isEqualTo: user.uid)
          .get();

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('✅ Historial de búsquedas limpiado');
    } catch (e) {
      print('❌ Error limpiando historial de búsquedas: $e');
      rethrow;
    }
  }

  /// Calcular distancia entre dos puntos (fórmula de Haversine)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Radio de la Tierra en km
    
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

  String _getDayName(int weekday) {
    const days = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
    return days[weekday - 1];
  }
}

// Extensión para convertir grados a radianes
extension on double {
  double toRadians() => this * (3.14159265359 / 180);
}
