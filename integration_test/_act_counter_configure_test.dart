import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/logger/i/type.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/main.dart';

void main() {
  LogService(Level.verbose);

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testActCounterConfigure();
}

void testActCounterConfigure() => group(
      'ActCounterConfigure test',
      () {
        testWidgets(
          ': launchActCounterConfigure',
          (widgetTester) async {
            await launchActCounterConfigure();
            await widgetTester.pumpAndSettle();
            await widgetTester.pumpAndSettle();
            await widgetTester.pumpAndSettle();

            expect(
              (widgetTester.widget(find.byType(Text).at(0)) as Text).data,
              'Select target',
            );
            expect(find.byIcon(Icons.check), findsOneWidget);
          },
        );
      },
    );
