import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
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
      final about1MonthAgo = DateTime.now().subtract(const Duration(days: 32));

      const insertedMemHasNoPeriod = '$scenarioName - mem name - no period';
      const insertedMemHasPeriodStart =
          '$scenarioName - mem name - has period start';
      final insertedMemPeriodStart =
          about1MonthAgo.add(const Duration(days: 2));
      const insertedMemHasPeriodEnd =
          '$scenarioName - mem name - has period end';
      final insertedMemPeriodEnd =
          about1MonthAgo.add(const Duration(days: 3, minutes: 10));
      const insertedMemHasPeriod = '$scenarioName - mem name - has period';
      final insertedMemPeriod = WithStartAndEnd(
        DateAndTime.from(
            about1MonthAgo.add(const Duration(days: 4, minutes: 20)),
            timeOfDay:
                about1MonthAgo.add(const Duration(days: 4, minutes: 20))),
        DateAndTime.from(
          about1MonthAgo.add(const Duration(days: 5, minutes: 30)),
          timeOfDay: about1MonthAgo.add(const Duration(days: 5, minutes: 30)),
        ),
      );

      late final DatabaseAccessor dbA;

      setUpAll(() async {
        dbA = await openTestDatabase(databaseDefinition);
      });
      setUp(() async {
        await clearAllTestDatabaseRows(databaseDefinition);

        await dbA.insert(defTableMems, {
          defColMemsName.name: insertedMemHasNoPeriod,
          defColMemsStartOn.name: null,
          defColMemsStartAt.name: null,
          defColMemsEndOn.name: null,
          defColMemsEndAt.name: null,
          defColCreatedAt.name: zeroDate,
        });
        await dbA.insert(defTableMems, {
          defColMemsName.name: insertedMemHasPeriodStart,
          defColMemsStartOn.name: insertedMemPeriodStart,
          defColCreatedAt.name: zeroDate,
        });
        await dbA.insert(defTableMems, {
          defColMemsName.name: insertedMemHasPeriodEnd,
          defColMemsEndOn.name: insertedMemPeriodEnd,
          defColMemsEndAt.name: insertedMemPeriodEnd,
          defColCreatedAt.name: zeroDate,
        });
        await dbA.insert(defTableMems, {
          defColMemsName.name: insertedMemHasPeriod,
          defColMemsStartOn.name: insertedMemPeriod.start.dateTime,
          defColMemsStartAt.name: insertedMemPeriod.start.dateTime,
          defColMemsEndOn.name: insertedMemPeriod.end.dateTime,
          defColMemsEndAt.name: insertedMemPeriod.end.dateTime,
          defColCreatedAt.name: zeroDate,
        });
      });

      group(": show Period", () {
        testWidgets(": new Mem has no period.", (widgetTester) async {
          await runApplication();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(newMemFabFinder);
          await widgetTester.pumpAndSettle();

          expect(find.text(datePlaceHolder), findsNWidgets(2));
          expect(calendarIconFinder, findsNWidgets(2));
          expect(find.byType(Switch), findsNWidgets(2));
          expect(
            widgetTester.widget<Switch>(find.byType(Switch).at(0)).value,
            true,
          );
          expect(
            widgetTester.widget<Switch>(find.byType(Switch).at(1)).value,
            true,
          );
          expect(timeIconFinder, findsNothing);
        });

        group(": inserted Mem", () {
          testWidgets(": on MemList", (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            final expectedList = [
              insertedMemHasPeriodStart,
              dateText(insertedMemPeriodStart),
              "~",
              insertedMemHasPeriodEnd,
              "~",
              dateText(insertedMemPeriodEnd),
              " ",
              timeText(insertedMemPeriodEnd),
              insertedMemHasPeriod,
              dateText(insertedMemPeriod.start),
              " ",
              timeText(insertedMemPeriod.start),
              "~",
              dateText(insertedMemPeriod.end),
              " ",
              timeText(insertedMemPeriod.end),
            ];
            final texts =
                widgetTester.widgetList<Text>(find.byType(Text)).toList();
            expectedList.forEachIndexed((index, expected) {
              expect(
                texts[index].data,
                expected,
                reason: "Index is $index.",
              );
            });
          });

          testWidgets(": has period start.", (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.text(insertedMemHasPeriodStart));
            await widgetTester.pumpAndSettle();

            expect(
              widgetTester
                  .widget<TextFormField>(find.byType(TextFormField).at(1))
                  .initialValue,
              dateText(insertedMemPeriodStart),
            );
            expect(
              widgetTester
                  .widget<TextFormField>(find.byType(TextFormField).at(2))
                  .initialValue,
              "",
            );
          });
          testWidgets(": has period end.", (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.text(insertedMemHasPeriodEnd));
            await widgetTester.pumpAndSettle();

            expect(
              widgetTester
                  .widget<TextFormField>(find.byType(TextFormField).at(1))
                  .initialValue,
              "",
            );
            expect(
              widgetTester
                  .widget<TextFormField>(find.byType(TextFormField).at(2))
                  .initialValue,
              dateText(insertedMemPeriodEnd),
            );
            expect(
              widgetTester
                  .widget<TextFormField>(find.byType(TextFormField).at(3))
                  .initialValue,
              timeText(insertedMemPeriodEnd),
            );
            expect(
              widgetTester.widget<Switch>(find.byType(Switch).at(1)).value,
              false,
            );
            expect(timeIconFinder, findsOneWidget);
          });
          testWidgets(": has period.", (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.text(insertedMemHasPeriod));
            await widgetTester.pumpAndSettle();

            expect(
              widgetTester
                  .widget<TextFormField>(find.byType(TextFormField).at(1))
                  .initialValue,
              dateText(insertedMemPeriod.start),
            );
            expect(
              widgetTester
                  .widget<TextFormField>(find.byType(TextFormField).at(2))
                  .initialValue,
              timeText(insertedMemPeriod.start),
            );
            expect(
              widgetTester.widget<Switch>(find.byType(Switch).at(0)).value,
              false,
            );
            expect(
              widgetTester
                  .widget<TextFormField>(find.byType(TextFormField).at(3))
                  .initialValue,
              dateText(insertedMemPeriod.end),
            );
            expect(
              widgetTester
                  .widget<TextFormField>(find.byType(TextFormField).at(4))
                  .initialValue,
              timeText(insertedMemPeriod.end),
            );
            expect(
              widgetTester.widget<Switch>(find.byType(Switch).at(1)).value,
              false,
            );
            expect(timeIconFinder, findsNWidgets(2));
          });
        });
      });

      testWidgets(
        ': Set Period.',
        (widgetTester) async {
          setMockLocalNotifications(widgetTester);

          final now = DateTime.now();

          await runApplication();
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(newMemFabFinder);
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(calendarIconFinder.at(0));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.byIcon(Icons.chevron_right).at(0));
          await widgetTester.pumpAndSettle();

          const pickingStartDate = 1;
          await widgetTester.tap(find.text('$pickingStartDate'));
          await widgetTester.tap(find.text('OK'));
          await widgetTester.pumpAndSettle();

          final startDate = DateTime(now.year, now.month + 1, pickingStartDate);
          expect(
            (widgetTester.widget(find.byType(TextFormField).at(1))
                    as TextFormField)
                .initialValue,
            dateText(startDate),
          );
          expect(timeIconFinder, findsNothing);

          await widgetTester.tap(find.byType(Switch).at(0));
          await widgetTester.pumpAndSettle();

          final pickingStartTime = DateTime.now();
          await widgetTester.tap(find.text('OK'));
          await widgetTester.pumpAndSettle();

          expect(
            (widgetTester.widget(find.byType(TextFormField).at(2))
                    as TextFormField)
                .initialValue,
            timeText(pickingStartTime),
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

          final endDate = DateTime(now.year, now.month + 2, pickingEndDate);
          expect(
            (widgetTester.widget(find.byType(TextFormField).at(3))
                    as TextFormField)
                .initialValue,
            dateText(endDate),
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
          expect(find.text(dateText(endDate)), findsOneWidget);
        },
      );
    });
