// lib/app/app.dart
import 'package:flutter/material.dart';

// Páginas
import 'package:kitit_v2/features/explore/explore_page.dart';
import 'package:kitit_v2/features/competition/competition_page.dart';
import 'package:kitit_v2/features/analisis/analisis_page.dart';
import 'package:kitit_v2/features/mercado/mercado_page.dart';

// Auth
import 'package:kitit_v2/features/auth/auth_wrapper.dart';

// Bottom nav
import 'package:kitit_v2/widgets/bottom_nav.dart';
import 'package:kitit_v2/widgets/user_profile_widget.dart';
import 'package:kitit_v2/widgets/glossary_term_widget.dart';

class KitItApp extends StatelessWidget {
  const KitItApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: Brightness.light,
    );
    
    return MaterialApp(
      title: 'exitoxy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        typography: Typography.material2021(),
        appBarTheme: AppBarTheme(
          backgroundColor: scheme.surface,
          foregroundColor: scheme.onSurface,
          elevation: 0,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          filled: true,
          fillColor: scheme.surfaceVariant.withOpacity(0.5),
        ),
      ),
      home: const AuthWrapper(
        child: HomeShell(),
      ),
    );
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  // Sin const para evitar errores si alguna página no tiene constructor const
  late final List<Widget> _pages = [
    ExplorePage(),
    CompetitionPage(),
    AnalisisPage(), // Análisis de estructura de mercado
    MercadoPage(), // Análisis de elasticidad
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'exitoxy',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Botón de Glosario
          IconButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const GlossaryPage()),
            ),
            icon: const Icon(Icons.menu_book_rounded),
            tooltip: 'Glosario de términos',
          ),
          const UserProfileWidget(),
          const SizedBox(width: 16),
        ],
      ),
      body: IndexedStack(index: _index, children: _pages),

      // ✅ ÚNICO lugar con barra inferior
      bottomNavigationBar: BottomNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
        items: const [
          BottomNavItem(icon: Icons.explore_rounded, label: 'Éxito XY'),
          BottomNavItem(icon: Icons.leaderboard_rounded, label: 'Competencia'),
          BottomNavItem(icon: Icons.analytics, label: 'Análisis'),
          BottomNavItem(icon: Icons.trending_up, label: 'Mercado'),
        ],
      ),
    );
  }
}
