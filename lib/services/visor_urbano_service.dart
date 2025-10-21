import 'dart:convert';
import 'package:http/http.dart' as http;

class VisorUrbanoService {
  static const String _baseUrl = 'https://visorurbano.com:3000/api/v2/catastro/predio';

  /// Busca predio por calle y número
  static Future<dynamic> searchPredioByName(String calle, String numeroExterior) async {
    try {
      final url = '$_baseUrl/search?calle=$calle&numeroExterior=$numeroExterior';
      print('🔍 Visor Urbano URL: $url');
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Visor Urbano: Predio encontrado');
        return data;
      } else {
        print('❌ Visor Urbano Error: ${response.statusCode}');
        throw Exception('Failed to load predio data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Visor Urbano Exception: $e');
      throw Exception('Error fetching predio data: $e');
    }
  }

  /// Busca predio por coordenadas
  static Future<dynamic> searchPredioByCoordinates(double lat, double lng) async {
    try {
      // Formatear coordenadas con 6 decimales
      final latFormatted = lat.toStringAsFixed(6);
      final lngFormatted = lng.toStringAsFixed(6);
      final url = '$_baseUrl/$latFormatted/$lngFormatted';
      print('🔍 Visor Urbano Coordenadas URL: $url');
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Visor Urbano: Predio encontrado por coordenadas');
        print('📊 Datos recibidos: ${data.toString()}');
        return data;
      } else {
        print('❌ Visor Urbano Error: ${response.statusCode}');
        print('❌ Response body: ${response.body}');
        throw Exception('Failed to load predio data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Visor Urbano Exception: $e');
      throw Exception('Error fetching predio data: $e');
    }
  }

  /// Mapea tipos de uso del suelo
  static String getTipoUsoNombre(String codigo) {
    const tiposUso = {
      'H': 'Habitacional',
      'H1': 'Habitacional1',
      'H2': 'Habitacional2',
      'H3': 'Habitacional3',
      'H4': 'Habitacional4',
      'H5': 'Habitacional5',
      'CS': 'Comercio y Servicios',
      'CS1': 'Comercio y Servicios Impacto Mínimo',
      'CS2': 'Comercio y Servicios Impacto Bajo',
      'CS3': 'Comercio y Servicios Impacto Medio',
      'CS4': 'Comercio y Servicios Impacto Alto',
      'CS5': 'Comercio y Servicios5 Impacto Máximo',
      'I': 'Industrial',
      'I1': 'Industrial Impacto Mínimo',
      'I2': 'Industrial Impacto Bajo',
      'I3': 'Industrial Impacto Medio',
      'I4': 'Industrial Impacto Alto',
      'I5': 'Industrial Industrial Impacto Máximo',
      'E': 'Equipamiento',
      'E1': 'Equipamiento Impacto Mínimo',
      'E2': 'Equipamiento Impacto Bajo',
      'E3': 'Equipamiento Impacto Medio',
      'E4': 'Equipamiento Impacto Alto',
      'E5': 'Equipamiento Impacto Máximo',
      'EA': 'Espacio Abierto',
      'RI': 'Restricción por Infraestructura',
      'RIE': 'Restricción por Infraestructura de instalaciones especiales',
      'RIS': 'Restricción por Infraestructura de servicios públicos',
      'RIT': 'Restricción por Infraestructura de transportes',
      'P': 'Proteccion Ambiental',
      'ANP': 'Área Natural Protegida',
      'PC': 'Conservación',
      'PRH': 'Protección de Recursos Hídricos',
      'ARN': 'Aprovechamiento de Recursos Naturales',
      'ED': 'Educativo',
      'CR': 'Cultural',
      'AS': 'Asistencia Social',
      'RE': 'Religioso',
      'CA': 'Comercio y Abasto',
      'DE': 'Deportivo',
      'AP': 'Administracion Publica'
    };

    return tiposUso[codigo] ?? 'Desconocido';
  }

  /// Procesa datos de predio y extrae información relevante
  static Map<String, dynamic> processPredioData(dynamic rawData) {
    try {
      if (rawData == null) {
        return {
          'success': false,
          'message': 'No se encontraron datos del predio'
        };
      }

      // Extraer información básica
      final predio = rawData['predio'] ?? {};
      final ubicacion = predio['ubicacion'] ?? {};
      final construccion = predio['construccion'] ?? {};
      final uso = predio['uso'] ?? {};

      return {
        'success': true,
        'predio': {
          'clave': predio['clave'] ?? 'N/A',
          'superficie_terreno': predio['superficie_terreno'] ?? 0,
          'superficie_construccion': predio['superficie_construccion'] ?? 0,
          'valor_terreno': predio['valor_terreno'] ?? 0,
          'valor_construccion': predio['valor_construccion'] ?? 0,
          'valor_total': predio['valor_total'] ?? 0,
        },
        'ubicacion': {
          'calle': ubicacion['calle'] ?? 'N/A',
          'numero_exterior': ubicacion['numero_exterior'] ?? 'N/A',
          'numero_interior': ubicacion['numero_interior'] ?? '',
          'colonia': ubicacion['colonia'] ?? 'N/A',
          'codigo_postal': ubicacion['codigo_postal'] ?? 'N/A',
          'municipio': ubicacion['municipio'] ?? 'N/A',
          'estado': ubicacion['estado'] ?? 'N/A',
        },
        'construccion': {
          'tipo': construccion['tipo'] ?? 'N/A',
          'antiguedad': construccion['antiguedad'] ?? 0,
          'pisos': construccion['pisos'] ?? 1,
          'habitaciones': construccion['habitaciones'] ?? 0,
          'banos': construccion['banos'] ?? 0,
        },
        'uso': {
          'codigo': uso['codigo'] ?? 'N/A',
          'descripcion': getTipoUsoNombre(uso['codigo'] ?? ''),
          'intensidad': uso['intensidad'] ?? 'N/A',
        }
      };
    } catch (e) {
      print('❌ Error procesando datos de predio: $e');
      return {
        'success': false,
        'message': 'Error procesando datos del predio: $e'
      };
    }
  }
}
