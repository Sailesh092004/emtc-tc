import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:emtc_app/main.dart';
import 'package:emtc_app/services/db_service.dart';
import 'package:emtc_app/services/sync_service.dart';

void main() {
  testWidgets('e-MTC TC App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(
      dbService: DatabaseService(),
      syncService: SyncService(DatabaseService()),
    ));

    // Verify that the app starts without crashing
    expect(find.byType(MaterialApp), findsOneWidget);
  });
} 