import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/acts/act_list_item_view.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/main.dart' as app;
import 'package:mem/repositories/i/_database_tuple_entity_v2.dart';
import 'package:mem/repositories/mem_entity.dart';

import '../_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  DatabaseManager(onTest: true);

  testActScenario();
}

void testActScenario() => group('Act scenario', () {
      const savedMemName = 'Memo scenario: V2: saved mem name';

      setUp(() async {
        final memTable =
            (await DatabaseManager(onTest: true).open(app.databaseDefinition))
                .getTable(memTableDefinition.name);

        await memTable.insert({
          defMemName.name: savedMemName,
          createdAtColumnName: DateTime.now(),
        });
      });

      testWidgets(
        ': start act.',
        (widgetTester) async {
          await app.main();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.text(savedMemName));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(showActPageIconFinder);
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.byIcon(Icons.play_arrow));

          expect(1, 1);
        },
      );

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
      );
    });

final showActPageIconFinder = find.byIcon(Icons.play_arrow);
final addActIconFinder = find.byIcon(Icons.add);
final actListItemFinder = find.byType(ActListItemView);
