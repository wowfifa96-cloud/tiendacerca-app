import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ferrecerca_app/main.dart';

// Autor: Roberto
// Prueba de humo: la app arranca sin errores.
void main() {
  testWidgets('App arranca y muestra la pantalla principal', (WidgetTester tester) async {
    await tester.pumpWidget(const TiendaCercaApp());
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
