import 'dart:convert';
import 'package:http/http.dart' as http;

class DenueService {
  static const String _baseUrl = 'https://www.inegi.org.mx/app/api/denue/v1/consulta';
  static const String _apiKey = 'd28a2536-ca8d-47da-bfac-6a57d5c396e0';
  static const String _entityApiKey = '319c3103-92db-49e2-9512-0ee285fe3ba9';

  /// Obtiene negocios DENUE por tipo de comercio y ubicación
  static Future<List<Map<String, dynamic>>> fetchBusinesses(
    String tipoComercio,
    double latitud,
    double longitud,
    {int radius = 1500}
  ) async {
    try {
      final url = '$_baseUrl/Buscar/$tipoComercio/$latitud,$longitud/$radius/$_apiKey';
      print('🔍 DENUE URL: $url');
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        List<Map<String, dynamic>> negocios = [];

        for (var element in data) {
          negocios.add({
            'lat': element["Latitud"],
            'lon': element["Longitud"],
            'nombre': element["Nombre"],
            'descripcion': element["Clase_actividad"],
            'codigo_actividad': element["Codigo_actividad"],
            'telefono': element["Telefono"],
            'correo': element["Correo_electronico"],
            'sitio_web': element["Sitio_internet"],
            'tipo_vialidad': element["Tipo_vialidad"],
            'nombre_vialidad': element["Nombre_vialidad"],
            'numero_exterior': element["Numero_exterior"],
            'numero_interior': element["Numero_interior"],
            'codigo_postal': element["Codigo_postal"],
            'asentamiento': element["Asentamiento"],
            'municipio': element["Municipio"],
            'estado': element["Estado"],
            'fecha_actualizacion': element["Fecha_actualizacion"],
          });
        }
        
        print('✅ DENUE: ${negocios.length} negocios encontrados');
        return negocios;
      } else {
        print('❌ DENUE Error: ${response.statusCode}');
        throw Exception('Failed to load DENUE data: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ DENUE Exception: $e');
      throw Exception('Error fetching DENUE data: $e');
    }
  }

  /// Verifica si una actividad económica existe
  static Future<bool> isEconomyActivity(String economyA) async {
    try {
      print('🔍 Verificando actividad económica: $economyA');
      final url = '$_baseUrl/BuscarEntidad/$economyA/14/1/1/$_entityApiKey';
      
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        print('✅ Actividad económica válida');
        return true;
      } else if (response.statusCode == 404) {
        print('❌ Actividad económica no encontrada');
        return false;
      } else {
        print('❌ Error verificando actividad: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Error verificando actividad económica: $e');
      return false;
    }
  }

  /// Obtiene tipos de comercio populares
  static List<String> getPopularBusinessTypes() {
    return [
      'Restaurantes',
      'Farmacias',
      'Supermercados',
      'Gasolineras',
      'Hospitales',
      'Escuelas',
      'Bancos',
      'Oficinas',
      'Tiendas de ropa',
      'Electrónicos',
      'Muebles',
      'Automóviles',
      'Hoteles',
      'Gimnasios',
      'Librerías',
    ];
  }
}
