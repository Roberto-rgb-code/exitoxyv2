import 'package:kitit_v2/models/concentration_result.dart';

class _CacheEntry {
  final ConcentrationResult result;
  final DateTime timestamp;

  _CacheEntry(this.result, this.timestamp);

  /// Verifica si la entrada ha expirado (TTL de 30 minutos)
  bool get isExpired {
    return DateTime.now().difference(timestamp).inMinutes > 30;
  }
  
  /// Verifica si los datos parecen ser de fallback (nombres genéricos)
  bool get seemsFallback {
    // Si los nombres siguen un patrón como "actividad 1", "actividad 2", etc.
    final chains = result.topChains;
    if (chains.length < 2) return false;
    
    // Verificar si hay patrones numéricos consecutivos
    int numericPatterns = 0;
    for (final chain in chains) {
      if (RegExp(r'\d+$').hasMatch(chain)) {
        numericPatterns++;
      }
    }
    
    // Si más del 50% de los nombres terminan en número, probablemente es fallback viejo
    return numericPatterns > chains.length * 0.5;
  }
}

class CacheService {
  static final Map<String, _CacheEntry> _cache = {};

  /// Genera una clave única para el cache
  static String _generateKey(String activity, String postalCode) {
    return '${activity.toLowerCase().trim()}|${postalCode.trim()}';
  }

  /// Obtiene un resultado del cache (solo si no ha expirado y no es fallback viejo)
  static ConcentrationResult? get(String activity, String postalCode) {
    final key = _generateKey(activity, postalCode);
    final entry = _cache[key];
    
    if (entry == null) return null;
    
    // Invalidar si ha expirado
    if (entry.isExpired) {
      print('⏰ Cache expirado para: $key');
      _cache.remove(key);
      return null;
    }
    
    // Invalidar si parece ser datos de fallback viejos
    if (entry.seemsFallback) {
      print('🔄 Cache con datos de fallback viejos detectado: $key');
      _cache.remove(key);
      return null;
    }
    
    return entry.result;
  }

  /// Guarda un resultado en el cache
  static void put(String activity, String postalCode, ConcentrationResult result) {
    final key = _generateKey(activity, postalCode);
    _cache[key] = _CacheEntry(result, DateTime.now());
  }

  /// Limpia todo el cache
  static void clear() {
    print('🧹 Limpiando todo el cache (${_cache.length} entradas)');
    _cache.clear();
  }
  
  /// Limpia entradas expiradas del cache
  static void cleanExpired() {
    final expiredKeys = <String>[];
    _cache.forEach((key, entry) {
      if (entry.isExpired || entry.seemsFallback) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _cache.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      print('🧹 Cache limpiado: ${expiredKeys.length} entradas expiradas/fallback');
    }
  }

  /// Obtiene el tamaño del cache
  static int size() {
    return _cache.length;
  }

  /// Verifica si existe una entrada válida en el cache
  static bool contains(String activity, String postalCode) {
    return get(activity, postalCode) != null;
  }
  
  /// Invalida una entrada específica del cache
  static void invalidate(String activity, String postalCode) {
    final key = _generateKey(activity, postalCode);
    _cache.remove(key);
    print('🗑️ Cache invalidado para: $key');
  }
}
