import 'package:flutter/material.dart';

class ParcelPage extends StatelessWidget {
  const ParcelPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: const [
        SizedBox(height: 16),
        _Header('Predio / Uso de Suelo'),
        _CardHint('Consulta Visor Urbano por coordenadas o dirección.'),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final String text;
  const _Header(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );
}

class _CardHint extends StatelessWidget {
  final String text;
  const _CardHint(this.text, {super.key});
  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(text),
    ),
  );
}
