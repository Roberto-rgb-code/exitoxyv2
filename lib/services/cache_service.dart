import '../models/concentration_result.dart';

class CacheService {
  final Map<String, ConcentrationResult> _mem = {};

  String _key(String activity, String? postalCode) =>
      '${activity.toLowerCase().trim()}|${postalCode ?? 'none'}';

  bool has(String activity, String? postalCode) =>
      _mem.containsKey(_key(activity, postalCode));

  ConcentrationResult? get(String activity, String? postalCode) =>
      _mem[_key(activity, postalCode)];

  void put(String activity, String? postalCode, ConcentrationResult v) =>
      _mem[_key(activity, postalCode)] = v;

  void clear() => _mem.clear();
}
