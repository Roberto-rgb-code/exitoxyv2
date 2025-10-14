import 'package:flutter/material.dart';

class FilteringService {
  /// Filtra la lista de datos comerciales según los criterios especificados
  static List<Map<String, dynamic>> filterCommercialData(
    List<Map<String, dynamic>> data,
    Map<String, dynamic> filters,
  ) {
    final List<Map<String, dynamic>> filteredList = [];

    for (final place in data) {
      bool passesFilter = true;

      // Filtro por superficie (m2)
      if (filters['m2'] != null && passesFilter) {
        final rangeM2 = filters['m2'] as RangeValues;
        final superficie = double.tryParse(place['superficie_m3']?.toString() ?? '0') ?? 0;
        
        if (superficie < rangeM2.start || superficie > rangeM2.end) {
          passesFilter = false;
        }
      }

      // Filtro por precio
      if (filters['precio'] != null && passesFilter) {
        final rangePrice = filters['precio'] as RangeValues;
        final precio = double.tryParse(place['precio']?.toString() ?? '0') ?? 0;
        
        if (precio < rangePrice.start || precio > rangePrice.end) {
          passesFilter = false;
        }
      }

      // Filtro por habitaciones
      if (filters['habitaciones'] != null && passesFilter) {
        final habitaciones = place['num_cuartos']?.toString();
        if (habitaciones != filters['habitaciones']) {
          passesFilter = false;
        }
      }

      // Filtro por baños
      if (filters['banos'] != null && passesFilter) {
        final banos = place['num_banos']?.toString();
        if (banos != filters['banos']) {
          passesFilter = false;
        }
      }

      // Filtro por garage
      if (filters['garage'] != null && passesFilter) {
        final garage = place['num_cajones']?.toString();
        if (garage != filters['garage']) {
          passesFilter = false;
        }
      }

      if (passesFilter) {
        filteredList.add(place);
      }
    }

    return filteredList;
  }

  /// Verifica si hay filtros activos
  static bool hasActiveFilters(Map<String, dynamic> filters) {
    for (final value in filters.values) {
      if (value != null) {
        return true;
      }
    }
    return false;
  }

  /// Limpia todos los filtros
  static Map<String, dynamic> clearFilters(Map<String, dynamic> filters) {
    final clearedFilters = <String, dynamic>{};
    for (final key in filters.keys) {
      clearedFilters[key] = null;
    }
    return clearedFilters;
  }
}
