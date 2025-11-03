import 'package:flutter_dotenv/flutter_dotenv.dart';

class Config {
  // ===========================================
  // MAPBOX CONFIGURATION
  // ===========================================
  static String get mapboxAccessToken => 
      dotenv.env['MAPBOX_ACCESS_TOKEN'] ?? 
      'pk.eyJ1Ijoia2V2aW5yb2JlcnRvIiwiYSI6ImNtZ2hhcHAyZzB0bjQya29pcmtoa2xuMm0ifQ.FPM4l0bfhiwenMZ6jVr2kA';

  // ===========================================
  // GOOGLE SERVICES
  // ===========================================
  static String get googlePlacesApiKey => 
      dotenv.env['GOOGLE_PLACES_API_KEY'] ?? 
      'your_google_places_api_key_here';

  static String get googleMapsApiKey => 
      dotenv.env['GOOGLE_MAPS_API_KEY'] ?? 
      'your_google_maps_api_key_here';

  // ===========================================
  // DATABASE CONFIGURATION
  // ===========================================
  static String get mysqlHost => 
      dotenv.env['MYSQL_HOST'] ?? '10.0.2.2';

  static int get mysqlPort => 
      int.tryParse(dotenv.env['MYSQL_PORT'] ?? '3306') ?? 3306;

  static String get mysqlUsername => 
      dotenv.env['MYSQL_USERNAME'] ?? 'root';

  static String get mysqlPassword => 
      dotenv.env['MYSQL_PASSWORD'] ?? 'kevin';

  static String get mysqlDatabase => 
      dotenv.env['MYSQL_DATABASE'] ?? 'kikit';

  // ===========================================
  // POSTGRESQL DATABASE CONFIGURATION (Render)
  // ===========================================
  static String get postgresHost => 
      dotenv.env['POSTGRES_HOST'] ?? 
      'dpg-d444266mcj7s73bmcar0-a.oregon-postgres.render.com';
  
  static int get postgresPort => 
      int.tryParse(dotenv.env['POSTGRES_PORT'] ?? '5432') ?? 5432;
  
  static String get postgresDatabase => 
      dotenv.env['POSTGRES_DATABASE'] ?? 'gis_db_kmw5';
  
  static String get postgresUsername => 
      dotenv.env['POSTGRES_USERNAME'] ?? 'gis_db_kmw5_user';
  
  static String get postgresPassword => 
      dotenv.env['POSTGRES_PASSWORD'] ?? 'giqLt0wGTmmnBBeAtzGp8ur4r0IOYc9e';
  
  static bool get postgresSslRequired => true;

  // ===========================================
  // API ENDPOINTS
  // ===========================================
  static String get apiBaseUrl => 
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3001';

  static String get visorUrbanoApiUrl => 
      dotenv.env['VISOR_URBANO_API_URL'] ?? 
      'https://visorurbano.com:3000/api/v2/catastro';

  // ===========================================
  // GOOGLE SHEETS
  // ===========================================
  static String get googleSheetsCredentials {
    final credentials = dotenv.env['GOOGLE_SHEETS_CREDENTIALS'];
    if (credentials == null || credentials.isEmpty) {
      throw Exception('GOOGLE_SHEETS_CREDENTIALS no está configurado en .env');
    }
    return credentials;
  }

  static String get googleSheetsSpreadsheetId {
    final spreadsheetId = dotenv.env['GOOGLE_SHEETS_SPREADSHEET_ID'];
    if (spreadsheetId == null || spreadsheetId.isEmpty) {
      throw Exception('GOOGLE_SHEETS_SPREADSHEET_ID no está configurado en .env');
    }
    return spreadsheetId;
  }

  // ===========================================
  // DENUE API
  // ===========================================
  static String get denueApiKey => 
      dotenv.env['DENUE_API_KEY'] ?? 
      'd28a2536-ca8d-47da-bfac-6a57d5c396e0';

  static String get denueValidationApiKey => 
      dotenv.env['DENUE_VALIDATION_API_KEY'] ?? 
      '319c3103-92db-49e2-9512-0ee285fe3ba9';

  // ===========================================
  // DEVELOPMENT SETTINGS
  // ===========================================
  static bool get debugMode => 
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';

  static String get logLevel => 
      dotenv.env['LOG_LEVEL'] ?? 'info';

  // ===========================================
  // VALIDATION METHODS
  // ===========================================
  static bool get hasValidGooglePlacesKey => 
      googlePlacesApiKey != 'your_google_places_api_key_here' && 
      googlePlacesApiKey.isNotEmpty;

  static bool get hasValidGoogleMapsKey => 
      googleMapsApiKey != 'your_google_maps_api_key_here' && 
      googleMapsApiKey.isNotEmpty;

  static bool get hasValidMapboxToken => 
      mapboxAccessToken.isNotEmpty && 
      mapboxAccessToken.startsWith('pk.');

  // ===========================================
  // INITIALIZATION
  // ===========================================
  static Future<void> load() async {
    try {
      await dotenv.load(fileName: ".env");
      if (debugMode) {
        print('✅ Environment variables loaded successfully');
        _printConfigStatus();
      }
    } catch (e) {
      print('⚠️ Could not load .env file: $e');
      print('Using default configuration values');
    }
  }

  static void _printConfigStatus() {
    print('📋 Configuration Status:');
    print('  🗺️  Mapbox Token: ${hasValidMapboxToken ? "✅ Valid" : "❌ Invalid"}');
    print('  🏪 Google Places: ${hasValidGooglePlacesKey ? "✅ Valid" : "❌ Invalid"}');
    print('  🗺️  Google Maps: ${hasValidGoogleMapsKey ? "✅ Valid" : "❌ Invalid"}');
    print('  🗄️  MySQL Host: $mysqlHost:$mysqlPort');
    print('  🌐 API Base URL: $apiBaseUrl');
    print('  📊 Debug Mode: $debugMode');
  }
}
