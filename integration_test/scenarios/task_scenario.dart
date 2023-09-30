import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/databases/definition.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testTaskScenario();
}

const scenarioName = 'Task scenario';

void testTaskScenario() => group(': $scenarioName', () {
      late final DatabaseAccessor dbA;

      setUpAll(() async {
        dbA = await openTestDatabase(databaseDefinition);
      });
      setUp(() async {
        await clearAllTestDatabaseRows(databaseDefinition);

        await dbA.insert(defTableMems, {
          defColMemsName.name: '$scenarioName - mem name - has period',
          defColMemsStartOn.name: DateTime.now(),
          defColCreatedAt.name: zeroDate,
        });
        await dbA.insert(defTableMems, {
          defColMemsName.name: '$scenarioName - mem name - no period',
          defColMemsStartOn.name: null,
          defColMemsStartAt.name: null,
          defColMemsEndOn.name: null,
          defColMemsEndAt.name: null,
          defColCreatedAt.name: zeroDate,
        });
      });

      testWidgets(
        ': Set Period.',
        (widgetTester) async {
          final now = DateTime.now();

          await runApplication();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(newMemFabFinder);
          await widgetTester.pumpAndSettle();

          expect(find.text('M/d/y'), findsNWidgets(2));
          expect(calendarIconFinder, findsNWidgets(2));
          expect(find.byType(Switch), findsNWidgets(2));
          expect(timeIconFinder, findsOneWidget);
          await widgetTester.tap(calendarIconFinder.at(0));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.byIcon(Icons.chevron_right).at(0));
          await widgetTester.pumpAndSettle();

          const pickingStartDate = 1;
          await widgetTester.tap(find.text('$pickingStartDate'));
          await widgetTester.tap(find.text('OK'));
          await widgetTester.pumpAndSettle();

          final startDate = '${now.month + 1}/$pickingStartDate/${now.year}';
          expect(
            (widgetTester.widget(find.byType(TextFormField).at(1))
                    as TextFormField)
                .initialValue,
            startDate,
          );
          expect(timeIconFinder, findsOneWidget);

          await widgetTester.tap(find.byType(Switch).at(0));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.text('OK'));
          await widgetTester.pumpAndSettle();

          final start = DateTime.now();
          final startTime = timeText(start);
          expect(
            (widgetTester.widget(find.byType(TextFormField).at(2))
                    as TextFormField)
                .initialValue,
            startTime,
          );
          expect(timeIconFinder, findsNWidgets(2));

          await widgetTester.tap(calendarIconFinder.at(1));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.byIcon(Icons.chevron_right).at(0));
          await widgetTester.pumpAndSettle();

          const pickingEndDate = 28;
          await widgetTester.tap(find.text('$pickingEndDate'));
          await widgetTester.tap(find.text('OK'));
          await widgetTester.pumpAndSettle();

          final endDate =
              dateText(DateTime(now.year, now.month + 2, pickingEndDate));
          expect(
            (widgetTester.widget(find.byType(TextFormField).at(3))
                    as TextFormField)
                .initialValue,
            endDate,
          );

          const enteringMemName =
              '$scenarioName: Set Period - mem name - entering';
          await widgetTester.enterText(
            memNameOnDetailPageFinder,
            enteringMemName,
          );
          await widgetTester.tap(saveMemFabFinder);
          await widgetTester.pumpAndSettle();

          await widgetTester.pageBack();
          await widgetTester.pumpAndSettle();

          expect(find.text(enteringMemName), findsOneWidget);
          final savedMemStartAt = (await dbA.select(
            defTableMems,
            where: "${defColMemsName.name} = ?",
            whereArgs: [enteringMemName],
          ))
              .single[defColMemsStartAt.name] as DateTime;

          expect(find.text(dateText(savedMemStartAt)), findsOneWidget);
          expect(find.text(timeText(savedMemStartAt)), findsOneWidget);
          expect(find.text(endDate), findsOneWidget);
        },
      );
    });
