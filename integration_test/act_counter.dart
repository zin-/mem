import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/logger/i/type.dart';
import 'package:mem/main.dart';

void main() {
  initializeLogger(Level.verbose);

  DatabaseManager(onTest: true);

  testWidgets(
    'launchActCounterConfigure',
    (widgetTester) async {
      await launchActCounterConfigure();
      await widgetTester.pumpAndSettle();

      expect(find.text('Select target'), findsOneWidget);
      expect(find.byIcon(Icons.check), findsOneWidget);
    },
  );
}
