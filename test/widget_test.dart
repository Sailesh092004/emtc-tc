import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mtc_nanna_app/main.dart';

void main() {
  testWidgets('eMTC App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp(
      dbService: null,
      syncService: null,
    ));

    // Verify that the app starts without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
} 