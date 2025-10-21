import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'app/app.dart';
import 'core/app_state.dart';
import 'core/config.dart';
import 'services/cache_service.dart';
import 'services/auth_service.dart';
import 'services/delitos_service.dart';
import 'services/search_history_service.dart';
import 'services/recommendation_service.dart';
import 'features/explore/explore_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Inicializar Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🔧 Cargar variables de entorno
  await Config.load();

  // 🗺️ Configurar Mapbox globalmente
  MapboxOptions.setAccessToken(Config.mapboxAccessToken);

        runApp(
          MultiProvider(
            providers: [
              Provider<CacheService>(create: (_) => CacheService()),
              ChangeNotifierProvider<AuthService>(create: (_) => AuthService()),
              ChangeNotifierProvider<AppState>(create: (_) => AppState()),
              ChangeNotifierProvider<ExploreController>(
                create: (_) => ExploreController(),
              ),
              Provider<DelitosService>(create: (_) => DelitosService()),
              Provider<SearchHistoryService>(create: (_) => SearchHistoryService()),
              Provider<RecommendationService>(create: (_) => RecommendationService()),
            ],
            child: const KitItApp(),
          ),
        );
}
