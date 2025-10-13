import 'package:flutter/material.dart';

class Map3DPage extends StatelessWidget {
  const Map3DPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text('Mapa 3D', style: Theme.of(context).textTheme.titleLarge),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            height: 380,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            alignment: Alignment.center,
            child: Text('Aquí irá Mapbox 3D (Paso 3)', style: TextStyle(color: cs.primary, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }
}
