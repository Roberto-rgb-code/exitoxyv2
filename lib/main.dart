import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

import 'app/app.dart';
import 'core/app_state.dart';
import 'core/config.dart';
import 'services/cache_service.dart';
import 'features/explore/explore_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔧 Cargar variables de entorno
  await Config.load();

  // 🗺️ Configurar Mapbox globalmente
  MapboxOptions.setAccessToken(Config.mapboxAccessToken);

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
