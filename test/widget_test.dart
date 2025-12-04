// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kitit_v2/features/competition/competition_page.dart';

void main() {
  testWidgets('CompetitionPage muestra título y botón de cálculo',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CompetitionPage(),
      ),
    );

    // Verifica título en AppBar
    expect(find.text('Competencia'), findsOneWidget);

    // Verifica que existe el botón principal de cálculo
    expect(find.byIcon(Icons.bar_chart_rounded), findsOneWidget);
    expect(find.text('Calcular'), findsOneWidget);
  });
}
