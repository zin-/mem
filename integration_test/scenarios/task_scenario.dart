import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/main.dart' as app;
import 'package:mem/repositories/_database_tuple_repository.dart';
import 'package:mem/repositories/mem_entity.dart';

import '../_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testTaskScenario();
}

const scenarioName = 'Task scenario';

void testTaskScenario() => group(': $scenarioName', () {
      late final Database db;

      setUpAll(() async {
        db = await DatabaseManager(onTest: true).open(app.databaseDefinition);
      });
      setUp(() async {
        final memTable = db.getTable(memTableDefinition.name);

        await memTable.insert({
          defMemName.name: '$scenarioName: has period',
          defMemStartOn.name: DateTime.now(),
          createdAtColumnName: DateTime.now(),
        });
        await memTable.insert({
          defMemName.name: '$scenarioName: no period',
          defMemStartOn.name: null,
          defMemStartAt.name: null,
          defMemEndOn.name: null,
          defMemEndAt.name: null,
          createdAtColumnName: DateTime.now(),
        });
      });
      tearDownAll(() async {
        await DatabaseManager(onTest: true).delete(app.databaseDefinition.name);
      });

      testWidgets(
        ': Set Period.',
        (widgetTester) async {
          final now = DateTime.now();

          await app.main();
          await widgetTester.pumpAndSettle();
          await widgetTester.pumpAndSettle();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(newMemFabFinder);
          await widgetTester.pumpAndSettle();

          expect(find.text('M/d/y'), findsNWidgets(2));
          expect(calendarIconFinder, findsNWidgets(2));
          expect(switchFinder, findsNWidgets(2));
          expect(timeIconFinder, findsNothing);
          await widgetTester.tap(calendarIconFinder.at(0));
          await widgetTester.pumpAndSettle();

          const pickingStartDate = 1;
          await widgetTester.tap(find.text('$pickingStartDate'));
          await widgetTester.tap(find.text('OK'));
          await widgetTester.pumpAndSettle();

          final startDate = '${now.month}/$pickingStartDate/${now.year}';
          expect(
            (widgetTester.widget(find.byType(TextFormField).at(1))
                    as TextFormField)
                .initialValue,
            startDate,
          );
          expect(timeIconFinder, findsNothing);

          await widgetTester.tap(switchFinder.at(0));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.text('OK'));
          await widgetTester.pumpAndSettle();

          final start = DateTime.now();
          final startTime =
              '${now.hour == 0 ? 12 : now.hour > 12 ? now.hour - 12 : now.hour}'
              ':${start.minute < 10 ? 0 : ''}${start.minute}'
              ' ${start.hour > 12 ? 'PM' : 'AM'}';
          expect(
            (widgetTester.widget(find.byType(TextFormField).at(2))
                    as TextFormField)
                .initialValue,
            startTime,
          );
          expect(timeIconFinder, findsOneWidget);

          await widgetTester.tap(calendarIconFinder.at(1));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.byIcon(Icons.chevron_right).at(0));
          await widgetTester.pumpAndSettle();

          const pickingEndDate = 28;
          await widgetTester.tap(find.text('$pickingEndDate'));
          await widgetTester.tap(find.text('OK'));
          await widgetTester.pumpAndSettle();

          final endDate = '${now.month + 1}/$pickingEndDate/${now.year}';
          expect(
            (widgetTester.widget(find.byType(TextFormField).at(3))
                    as TextFormField)
                .initialValue,
            endDate,
          );

          await widgetTester.enterText(
            memNameTextFormFieldFinder,
            '$scenarioName: Set Period. - entering mem name ',
          );
          await widgetTester.tap(saveMemFabFinder);
          await widgetTester.pumpAndSettle();

          await widgetTester.pageBack();
          await widgetTester.pumpAndSettle();
        },
      );
    });

final newMemFabFinder = find.byIcon(Icons.add);
final calendarIconFinder = find.byIcon(Icons.calendar_month);
final switchFinder = find.byType(Switch);
final timeIconFinder = find.byIcon(Icons.access_time_outlined);
