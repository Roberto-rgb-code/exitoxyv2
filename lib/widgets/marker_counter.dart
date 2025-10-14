import 'package:flutter/material.dart';

class MarkerCounter extends StatelessWidget {
  final int count;

  const MarkerCounter({
    Key? key,
    required this.count,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.5),
        borderRadius: BorderRadius.circular(5),
      ),
      width: 70,
      height: 40,
      padding: const EdgeInsets.only(top: 5),
      child: Text(
        "$count \ncomercios",
        style: const TextStyle(fontSize: 12),
        textAlign: TextAlign.center,
      ),
    );
  }
}
