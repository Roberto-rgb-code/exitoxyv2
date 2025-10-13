import 'package:flutter/material.dart';

class DemographyPage extends StatelessWidget {
  const DemographyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('Demografía', style: TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}
