import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/logger/log.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/settings/client.dart';
import 'package:mem/settings/keys.dart';
import 'package:mem/settings/preference.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testTaskScenario();
}

const _scenarioName = "Task scenario";

void testTaskScenario() => group(': $_scenarioName', () {
      LogService.initialize(
        Level.verbose,
        const bool.fromEnvironment('CICD', defaultValue: false),
      );

      final about1MonthAgo = DateTime.now().subtract(const Duration(days: 32));

      const insertedMemHasNoPeriod = '$_scenarioName - mem name - no period';
      const insertedMemHasPeriodStart =
          '$_scenarioName - mem name - has period start';
      final insertedMemPeriodStart =
          about1MonthAgo.add(const Duration(days: 2));
      const insertedMemHasPeriodEnd =
          '$_scenarioName - mem name - has period end';
      final insertedMemPeriodEnd =
          about1MonthAgo.add(const Duration(days: 3, minutes: 10));
      const insertedMemHasPeriod = '$_scenarioName - mem name - has period';
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

      int? insertedMemHasPeriodId;
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
        insertedMemHasPeriodId = await dbA.insert(defTableMems, {
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

      group(
        ": Save period",
        () {
          testWidgets(
            ": start is all day.",
            (widgetTester) async {
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
              await widgetTester.tap(okFinder);
              await widgetTester.pumpAndSettle();

              final now = DateTime.now();
              final start = DateTime(
                now.year,
                now.month + 1,
                pickingStartDate,
              );
              expect(
                (widgetTester.widget(find.byType(TextFormField).at(1))
                        as TextFormField)
                    .initialValue,
                dateText(start),
              );
              expect(timeIconFinder, findsNothing);

              const enteringMemName =
                  "$_scenarioName: Save period: start is all day - mem name - entering";
              await widgetTester.enterText(
                memNameOnDetailPageFinder,
                enteringMemName,
              );
              await widgetTester.tap(saveMemFabFinder);
              await widgetTester.pumpAndSettle();

              final savedMems = await dbA.select(
                defTableMems,
                where: "${defColMemsName.name} = ?",
                whereArgs: [enteringMemName],
              );
              expect(savedMems, hasLength(1));
              expect(savedMems.single[defColMemsStartOn.name], equals(start));
            },
          );

          testWidgets(
            ": end is all day.",
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(newMemFabFinder);
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(calendarIconFinder.at(1));
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(okFinder);
              await widgetTester.pumpAndSettle();

              const enteringMemName =
                  "$_scenarioName: Save period: end is all day - mem name - entering";
              await widgetTester.enterText(
                memNameOnDetailPageFinder,
                enteringMemName,
              );
              await widgetTester.tap(saveMemFabFinder);
              await widgetTester.pumpAndSettle();

              final savedMems = await dbA.select(
                defTableMems,
                where: "${defColMemsName.name} = ?",
                whereArgs: [enteringMemName],
              );
              expect(savedMems, hasLength(1));
            },
          );

          testWidgets(
            ": start is not all day, end is all day.",
            (widgetTester) async {
              await PreferenceClient().receive(Preference(
                startOfDayKey,
                const TimeOfDay(hour: 1, minute: 0),
              ));

              await runApplication();
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(newMemFabFinder);
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(calendarIconFinder.at(0));
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(find.byIcon(Icons.chevron_right).at(0));
              await widgetTester.pumpAndSettle();
              const pickingDate = 1;
              await widgetTester.tap(find.text("$pickingDate"));
              await widgetTester.tap(okFinder);
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.byType(Switch).at(0));
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(okFinder);
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(calendarIconFinder.at(1));
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.text("$pickingDate"));
              await widgetTester.tap(okFinder);
              await widgetTester.pumpAndSettle();

              final now = DateTime.now();
              final endDate = DateTime(now.year, now.month + 1, pickingDate);
              expect(
                (widgetTester.widget(find.byType(TextFormField).at(3))
                        as TextFormField)
                    .initialValue,
                dateText(endDate),
              );

              const enteringMemName =
                  "$_scenarioName: Save Period: start is not all day, end is all day - mem name - entering";
              await widgetTester.enterText(
                memNameOnDetailPageFinder,
                enteringMemName,
              );
              await widgetTester.tap(saveMemFabFinder);
              await widgetTester.pumpAndSettle();

              final savedMems = (await dbA.select(
                defTableMems,
                where: "${defColMemsName.name} = ?",
                whereArgs: [enteringMemName],
              ));
              expect(savedMems, hasLength(1));
              expect(
                savedMems.single[defColMemsEndOn.name],
                equals(endDate),
              );
            },
          );
        },
      );

      group(
        'notification',
        () {
          setUp(
            () async {
              await dbA.insert(defTableActs, {
                defFkActsMemId.name: insertedMemHasPeriodId,
                defColActsStart.name: zeroDate.toIso8601String(),
                defColActsStartIsAllDay.name: 0,
                defColCreatedAt.name: zeroDate,
              });
            },
          );

          testWidgets(
            'not notify on active act.',
            (widgetTester) async {
              DatabaseTupleRepository.databaseAccessor = dbA;

              widgetTester.setMockFlutterLocalNotifications(
                [],
              );

              await NotificationClient().show(
                NotificationType.startMem,
                insertedMemHasPeriodId!,
              );

              widgetTester.clearMockFlutterLocalNotifications();
            },
          );
        },
      );
    });
