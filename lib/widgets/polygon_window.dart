import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class PolygonWindow extends StatelessWidget {
  final Map<String, dynamic> data;
  final Set<Polygon> listaPolygons;

  const PolygonWindow({
    Key? key,
    required this.data,
    required this.listaPolygons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(20)),
        color: Colors.orange,
      ),
      child: SizedBox(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 15),
                children: [
                  ListTile(
                    leading: const Icon(Icons.woman, color: Colors.white),
                    title: Text(
                      "Femenino: ${data["f"] ?? 0}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.man, color: Colors.white),
                    title: Text(
                      "Masculino: ${data["m"] ?? 0}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  ListTile(
                    leading: const Icon(Icons.people, color: Colors.white),
                    title: Text(
                      "Total: ${data["t"] ?? 0}",
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
