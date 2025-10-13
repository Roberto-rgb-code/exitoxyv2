import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'app/app.dart';
import 'core/app_state.dart';
import 'services/cache_service.dart';
import 'features/explore/explore_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // 🗺️ Configurar Mapbox globalmente
  // Puedes sobreescribir con: --dart-define=MAPBOX_ACCESS_TOKEN=pk...
  const envToken = String.fromEnvironment('MAPBOX_ACCESS_TOKEN', defaultValue:
      'pk.eyJ1Ijoia2V2aW5yb2JlcnRvIiwiYSI6ImNtZ2hhcHAyZzB0bjQya29pcmtoa2xuMm0ifQ.FPM4l0bfhiwenMZ6jVr2kA');
  MapboxOptions.setAccessToken(envToken);

  runApp(
    MultiProvider(
      providers: [
        Provider<CacheService>(create: (_) => CacheService()),
        ChangeNotifierProvider<AppState>(create: (_) => AppState()),
        ChangeNotifierProvider<ExploreController>(
          create: (_) => ExploreController(),
        ),
      ],
      child: const KitItApp(),
    ),
  );
}
