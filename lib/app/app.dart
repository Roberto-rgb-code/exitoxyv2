// lib/app/app.dart
import 'package:flutter/material.dart';

// Páginas
import 'package:kitit_v2/features/explore/explore_page.dart';
import 'package:kitit_v2/features/competition/competition_page.dart';
import 'package:kitit_v2/features/demography/demography_page.dart';
import 'package:kitit_v2/features/ageb/ageb_page.dart';
import 'package:kitit_v2/features/predio/predio_page.dart';
import 'package:kitit_v2/features/three_d/three_d_page.dart';

// Bottom nav (ruta corregida)
import 'package:kitit_v2/widgets/bottom_nav.dart';

class KitItApp extends StatelessWidget {
  const KitItApp({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.indigo);
    return MaterialApp(
      title: 'KitIt',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
      ),
      home: const HomeShell(),
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
    DemographyPage(),
    AgebPage(),
    PredioPage(),
    ThreeDPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _index, children: _pages),

      // ✅ ÚNICO lugar con barra inferior
      bottomNavigationBar: BottomNav(
        index: _index,
        onChanged: (i) => setState(() => _index = i),
        items: [
          const BottomNavItem(icon: Icons.explore_rounded, label: 'Explorar'),
          const BottomNavItem(icon: Icons.leaderboard_rounded, label: 'Competencia'),
          const BottomNavItem(icon: Icons.groups_2_rounded, label: 'Demografía'),
          const BottomNavItem(icon: Icons.layers_rounded, label: 'AGEB'),
          const BottomNavItem(icon: Icons.home_work_rounded, label: 'Predio'),
          const BottomNavItem(icon: Icons.threed_rotation_rounded, label: '3D'),
        ],
      ),
    );
  }
}
