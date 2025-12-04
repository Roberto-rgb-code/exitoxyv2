import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:kitit_v2/features/explore/explore_controller.dart';
import 'package:kitit_v2/models/concentration_result.dart';

void main() {
  group('ExploreController - simbología de polígonos y concentración', () {
    test('getPolygonsWithConcentration devuelve polígonos originales si no hay capa activa', () {
      final controller = ExploreController(autoEnsureLocation: false);

      controller.polygons.add(
        const Polygon(
          polygonId: PolygonId('ageb_1'),
          points: [
            LatLng(0, 0),
            LatLng(0, 1),
            LatLng(1, 1),
          ],
          strokeColor: Color(0xFF000000),
          fillColor: Color(0xFF000000),
        ),
      );

      final result = controller.getPolygonsWithConcentration();
      expect(result.length, 1);
      final polygon = result.first;
      expect(polygon.strokeColor, const Color(0xFF000000));
      expect(polygon.fillColor, const Color(0xFF000000));
    });

    test('getPolygonsWithConcentration aplica color de concentración cuando está activa', () {
      final controller = ExploreController(autoEnsureLocation: false);

      controller.polygons.add(
        const Polygon(
          polygonId: PolygonId('ageb_1'),
          points: [
            LatLng(0, 0),
            LatLng(0, 1),
            LatLng(1, 1),
          ],
          strokeColor: Color(0xFF000000),
          fillColor: Color(0xFF000000),
        ),
      );

      controller.showConcentrationLayer = true;
      controller.currentConcentration = const ConcentrationResult(
        hhi: 1200,
        cr4: 35,
        level: 'low',
        color: 0xFF123456,
        topChains: ['A'],
      );

      final result = controller.getPolygonsWithConcentration();
      expect(result.length, 1);
      final polygon = result.first;
      expect(polygon.strokeColor, const Color(0xFF123456));
      expect(polygon.fillColor, const Color(0xFF123456).withOpacity(0.3));
    });
  });
}


