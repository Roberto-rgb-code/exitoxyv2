import 'package:flutter/material.dart';

class ThreeDPage extends StatelessWidget {
  const ThreeDPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Text('Vista 3D', style: TextStyle(fontSize: 20)),
        ),
      ),
    );
  }
}
