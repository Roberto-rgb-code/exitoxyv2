import 'package:flutter/material.dart';

class ConcentrationLegend extends StatelessWidget {
  const ConcentrationLegend({super.key});

  Widget _item(Color c, String label) => Row(
    children: [
      Container(width: 14, height: 14,
        decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Text(label),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Concentración (HHI)', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _item(const Color(0xFFB7E1CD), 'HHI < 1500 (Baja)'),
            const SizedBox(height: 4),
            _item(const Color(0xFFFFF59D), '1500–2500 (Moderada)'),
            const SizedBox(height: 4),
            _item(const Color(0xFFFFB74D), '2500–5000 (Alta)'),
            const SizedBox(height: 4),
            _item(const Color(0xFFE57373), '> 5000 (Muy alta)'),
          ],
        ),
      ),
    );
  }
}
