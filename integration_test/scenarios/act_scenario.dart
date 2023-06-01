import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/acts/act_list_item_view.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/main.dart' as app;
import 'package:mem/repositories/i/_database_tuple_entity_v2.dart';
import 'package:mem/repositories/mem_entity.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  DatabaseManager(onTest: true);

  testActScenario();
}

void testActScenario() => group('Act scenario', () {
      const savedMemName = 'Act scenario: saved mem name';

      setUpAll(() async {
        final memTable =
            (await DatabaseManager(onTest: true).open(app.databaseDefinition))
                .getTable(memTableDefinition.name);

        await memTable.insert({
          defMemName.name: savedMemName,
          createdAtColumnName: DateTime.now(),
        });
      });
      tearDownAll(() async {
        await DatabaseManager(onTest: true).delete(app.databaseDefinition.name);
      });

      testWidgets(
        ': start & finish act.',
        (widgetTester) async {
          await app.main();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.text(savedMemName));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(showActPageIconFinder);
          await widgetTester.pumpAndSettle();

          expect(find.byIcon(Icons.stop), findsNothing);
          await widgetTester.tap(find.byIcon(Icons.play_arrow));
          await widgetTester.pumpAndSettle();

          expect(find.byIcon(Icons.play_arrow), findsNothing);
          final now = DateTime.now();
          final nowHour = now.hour < 10 ? '0${now.hour}' : '${now.hour}';
          final nowMinute =
              now.minute < 10 ? '0${now.minute}' : '${now.minute}';
          expect(
            find.text(
              '${now.month}/${now.day}/${now.year} $nowHour:$nowMinute',
            ),
            findsOneWidget,
          );

          await widgetTester.tap(find.byIcon(Icons.stop));
          await widgetTester.pumpAndSettle();

          expect(
            find.text(
              '${now.month}/${now.day}/${now.year} $nowHour:$nowMinute',
            ),
            findsNWidgets(2),
          );

          expect(find.byIcon(Icons.stop), findsNothing);
          await widgetTester.tap(find.byIcon(Icons.play_arrow));
          await widgetTester.pumpAndSettle();

          expect(
            find.text(
              '${now.month}/${now.day}/${now.year} $nowHour:$nowMinute',
            ),
            findsNWidgets(3),
          );
        },
      );
    });

final showActPageIconFinder = find.byIcon(Icons.play_arrow);
final addActIconFinder = find.byIcon(Icons.add);
final actListItemFinder = find.byType(ActListItemView);
