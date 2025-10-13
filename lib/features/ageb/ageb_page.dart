import 'package:flutter/material.dart';

class AgebPage extends StatelessWidget {
  const AgebPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('AGEB / Polígonos', style: TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}
