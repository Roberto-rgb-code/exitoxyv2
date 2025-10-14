import 'package:kitit_v2/models/concentration_result.dart';

class CacheService {
  static final Map<String, ConcentrationResult> _cache = {};

  /// Genera una clave única para el cache
  static String _generateKey(String activity, String postalCode) {
    return '${activity.toLowerCase().trim()}|${postalCode.trim()}';
  }

  /// Obtiene un resultado del cache
  static ConcentrationResult? get(String activity, String postalCode) {
    final key = _generateKey(activity, postalCode);
    return _cache[key];
  }

  /// Guarda un resultado en el cache
  static void put(String activity, String postalCode, ConcentrationResult result) {
    final key = _generateKey(activity, postalCode);
    _cache[key] = result;
  }

  /// Limpia todo el cache
  static void clear() {
    _cache.clear();
  }

  /// Obtiene el tamaño del cache
  static int size() {
    return _cache.length;
  }

  /// Verifica si existe una entrada en el cache
  static bool contains(String activity, String postalCode) {
    final key = _generateKey(activity, postalCode);
    return _cache.containsKey(key);
  }
}