// Test básico para VolunUPT
//
// Este test verifica que la aplicación se inicializa correctamente.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:volunupt/main.dart';

void main() {
  testWidgets('VolunUPT app smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const VolunUPTApp());

    // Verify that the app loads without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
