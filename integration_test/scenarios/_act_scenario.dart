import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/acts/act_list_item_view.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/main.dart' as app;

import '../_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  DatabaseManager(onTest: true);

  testActScenario();
}

void testActScenario() => group('Act scenario', () {
      testWidgets(
        'Save act',
        (widgetTester) async {
          await app.main(languageCode: 'en');
          await widgetTester.pump();

          await widgetTester.tap(newMemFabFinder);
          await widgetTester.pumpAndSettle();

          await widgetTester.enterText(
            memNameTextFormFieldFinder,
            'Save act - mem name',
          );
          await widgetTester.tap(saveMemFabFinder);
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(showActPageIconFinder);
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(addActIconFinder);
          await widgetTester.pumpAndSettle();

          expect(actListItemFinder, findsOneWidget);
        },
        tags: TestSize.medium,
      );
    });

final showActPageIconFinder = find.byIcon(Icons.play_arrow);
final addActIconFinder = find.byIcon(Icons.add);
final actListItemFinder = find.byType(ActListItemView);
