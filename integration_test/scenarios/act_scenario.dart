import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/components/timer.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/framework/database/factory.dart';
import 'package:mem/repositories/database_repository.dart';
import 'package:mem/values/durations.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testActScenario();
}

const _scenarioName = 'Act scenario';

void testActScenario() => group(': $_scenarioName', () {
      final showActPageIconFinder = find.byIcon(Icons.play_arrow);
      final startIconFinder = find.byIcon(Icons.play_arrow);
      final stopIconFinder = find.byIcon(Icons.stop);

      const insertedMemName = '$_scenarioName: inserted mem - name';

      late final DatabaseAccessor dbA;
      late final int insertedMemId;

      setUpAll(() async {
        DatabaseFactory.onTest = true;
        dbA = await DatabaseRepository().receive(databaseDefinition);

        for (var tableDefinition
            in databaseDefinition.tableDefinitions.reversed) {
          await dbA.delete(tableDefinition);
        }

        insertedMemId = await dbA.insert(
          defTableMems,
          {
            defColMemsName.name: insertedMemName,
            defColCreatedAt.name: zeroDate,
          },
        );
        await dbA.insert(
          defTableMems,
          {
            defColMemsName.name: "$insertedMemName - 2",
            defColCreatedAt.name: zeroDate,
          },
        );
        await dbA.insert(
          defTableMemNotifications,
          {
            defFkMemNotificationsMemId.name: insertedMemId,
            defColMemNotificationsTime.name: 1,
            defColMemNotificationsType.name:
                MemNotificationType.afterActStarted.name,
            defColMemNotificationsMessage.name:
                '$_scenarioName: mem notification message',
            defColCreatedAt.name: zeroDate,
          },
        );
      });
      setUp(() async {
        await dbA.delete(defTableActs);

        await dbA.insert(
          defTableActs,
          {
            defFkActsMemId.name: insertedMemId,
            defColActsStart.name: zeroDate,
            defColActsStartIsAllDay.name: 0,
            defColActsEnd.name: zeroDate,
            defColActsEndIsAllDay.name: 0,
            defColCreatedAt.name: zeroDate,
          },
        );
      });

      Future<void> showMemListPage(WidgetTester widgetTester) async {
        await runApplication();
        await widgetTester.pumpAndSettle();
      }

      group(': ActListPage', () {
        Future<void> showActListPage(WidgetTester widgetTester) async {
          await showMemListPage(widgetTester);

          await widgetTester.tap(find.text(insertedMemName));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(showActPageIconFinder);
          await widgetTester.pumpAndSettle();
        }

        group(": All", () {
          testWidgets(': show inserted acts.', (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byIcon(Icons.playlist_play));
            await widgetTester.pumpAndSettle();

            [
              "Acts",
              dateText(zeroDate),
              "1",
              dateText(zeroDate),
              " ",
              timeText(zeroDate),
              "~",
              dateText(zeroDate),
              " ",
              timeText(zeroDate),
              insertedMemName,
            ].forEachIndexed((index, t) {
              expect(
                (widgetTester.widget(find.byType(Text).at(index)) as Text).data,
                t,
                reason: "Index is \"$index\".",
              );
            });
            expect(startIconFinder, findsNothing);
            expect(stopIconFinder, findsNothing);
          });
        });

        group(": by Mem", () {
          group(": show inserted acts", () {
            setUp(() async {
              await dbA.insert(
                defTableActs,
                {
                  defFkActsMemId.name: insertedMemId,
                  defColActsStart.name: zeroDate,
                  defColActsStartIsAllDay.name: 0,
                  defColCreatedAt.name: zeroDate,
                },
              );
            });

            testWidgets(
              ": check.",
              (widgetTester) async {
                await showActListPage(widgetTester);

                [
                  insertedMemName,
                  dateText(zeroDate),
                  "2",
                  dateText(zeroDate),
                  " ",
                  timeText(zeroDate),
                  "~",
                  dateText(zeroDate),
                  " ",
                  timeText(zeroDate),
                  "~",
                  dateText(zeroDate),
                  " ",
                  timeText(zeroDate),
                ].forEachIndexed((index, t) {
                  expect(
                    (widgetTester.widget(find.byType(Text).at(index)) as Text)
                        .data,
                    t,
                    reason: "Index is \"$index\".",
                  );
                });
                expect(stopIconFinder, findsOneWidget);
              },
            );
          });

          testWidgets(
            ': start & finish act.',
            (widgetTester) async {
              await showActListPage(widgetTester);

              expect(stopIconFinder, findsNothing);
              final startTime = DateTime.now();
              await widgetTester.tap(startIconFinder);
              await Future.delayed(defaultTransitionDuration);
              await widgetTester.pumpAndSettle(waitSideEffectDuration);

              expect(startIconFinder, findsNothing);
              [
                insertedMemName,
                dateText(startTime),
                "1",
                dateText(startTime),
                " ",
                timeText(startTime),
                "~",
                dateText(zeroDate),
                "1",
                dateText(zeroDate),
                " ",
                timeText(zeroDate),
                "~",
                dateText(zeroDate),
                " ",
                timeText(zeroDate),
              ].forEachIndexed((index, t) {
                expect(
                  (widgetTester.widget(find.byType(Text).at(index)) as Text)
                      .data,
                  t,
                  reason: "Index is \"$index\".",
                );
              });
              final stopTime = DateTime.now();
              await widgetTester.tap(stopIconFinder);
              await Future.delayed(defaultTransitionDuration);
              await widgetTester.pumpAndSettle(waitSideEffectDuration);

              [
                insertedMemName,
                dateText(startTime),
                "1",
                dateText(startTime),
                " ",
                timeText(startTime),
                "~",
                dateText(stopTime),
                " ",
                timeText(stopTime),
                dateText(zeroDate),
                "1",
                dateText(zeroDate),
                " ",
                timeText(zeroDate),
                "~",
                dateText(zeroDate),
                " ",
                timeText(zeroDate),
              ].forEachIndexed((index, t) {
                expect(
                  (widgetTester.widget(find.byType(Text).at(index)) as Text)
                      .data,
                  t,
                  reason: "Index is \"$index\".",
                );
              });

              expect(stopIconFinder, findsNothing);
              final startTime2 = DateTime.now();
              await widgetTester.tap(startIconFinder);
              await Future.delayed(defaultTransitionDuration);
              await widgetTester.pumpAndSettle(waitSideEffectDuration);

              [
                insertedMemName,
                dateText(startTime2),
                "2",
                dateText(startTime2),
                " ",
                timeText(startTime2),
                "~",
                dateText(startTime),
                " ",
                timeText(startTime),
                "~",
                dateText(stopTime),
                " ",
                timeText(stopTime),
                dateText(zeroDate),
                "1",
                dateText(zeroDate),
                " ",
                timeText(zeroDate),
                "~",
                dateText(zeroDate),
                " ",
                timeText(zeroDate),
              ].forEachIndexed((index, t) {
                expect(
                  (widgetTester.widget(find.byType(Text).at(index)) as Text)
                      .data,
                  t,
                  reason: "Index is \"$index\".",
                );
              });
            },
          );

          group(': Edit act', () {
            setUp(() async {
              await dbA.insert(
                defTableActs,
                {
                  defFkActsMemId.name: insertedMemId,
                  defColActsStart.name: zeroDate,
                  defColActsStartIsAllDay.name: 0,
                  defColCreatedAt.name: zeroDate,
                },
              );
            });

            testWidgets(': save.', (widgetTester) async {
              await showActListPage(widgetTester);

              await widgetTester.longPress(find.text(dateText(zeroDate)).at(1));
              await widgetTester.pumpAndSettle();

              final pickedDate = DateTime.now();
              await widgetTester.tap(find.byType(Switch).at(1));
              await widgetTester.pump();

              await widgetTester.tap(find.text('OK'));
              await widgetTester.pump();

              await widgetTester.tap(find.byIcon(Icons.save_alt));
              await widgetTester.pumpAndSettle(waitSideEffectDuration);

              [
                insertedMemName,
                dateText(zeroDate),
                "2",
                dateText(zeroDate),
                " ",
                timeText(zeroDate),
                "~",
                dateText(pickedDate),
                " ",
                timeText(pickedDate),
                dateText(zeroDate),
                " ",
                timeText(zeroDate),
                "~",
                dateText(zeroDate),
                " ",
                timeText(zeroDate),
              ].forEachIndexed((index, t) {
                expect(
                  (widgetTester.widget(find.byType(Text).at(index)) as Text)
                      .data,
                  t,
                  reason: "Index is \"$index\".",
                );
              });

              await widgetTester.longPress(find.text(dateText(zeroDate)).at(2));
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.byIcon(Icons.clear).at(1));
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.byIcon(Icons.save_alt));
              await widgetTester.pumpAndSettle(waitSideEffectDuration);

              [
                insertedMemName,
                dateText(zeroDate),
                "2",
                dateText(zeroDate),
                " ",
                timeText(zeroDate),
                "~",
                dateText(zeroDate),
                " ",
                timeText(zeroDate),
                "~",
                dateText(pickedDate),
                " ",
                timeText(pickedDate),
              ].forEachIndexed((index, t) {
                expect(
                  (widgetTester.widget(find.byType(Text).at(index)) as Text)
                      .data,
                  t,
                  reason: "Index is \"$index\".",
                );
              });
            });

            testWidgets(': delete.', (widgetTester) async {
              await showActListPage(widgetTester);

              await widgetTester.longPress(find.text(dateText(zeroDate)).at(1));
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.byIcon(Icons.delete));
              await widgetTester.pumpAndSettle();

              [
                insertedMemName,
                dateText(zeroDate),
                "1",
                dateText(zeroDate),
                " ",
                timeText(zeroDate),
                "~",
                dateText(zeroDate),
                " ",
                timeText(zeroDate),
              ].forEachIndexed((index, t) {
                expect(
                  (widgetTester.widget(find.byType(Text).at(index)) as Text)
                      .data,
                  t,
                  reason: "Index is \"$index\".",
                );
              });
            });
          });
        });
      });

      group(": ActLineChartPage", () {
        setUp(() async {
          final now = DateTime.now();

          await dbA.delete(defTableActs);

          await dbA.insert(
            defTableActs,
            {
              defFkActsMemId.name: insertedMemId,
              defColActsStart.name: DateTime(now.year, now.month - 1, 28),
              defColActsStartIsAllDay.name: 0,
              defColActsEnd.name: now,
              defColActsEndIsAllDay.name: 0,
              defColCreatedAt.name: zeroDate,
            },
          );
          for (int i = 0; i < 6; i++) {
            final start = now.subtract(Duration(days: i));
            for (int j = 0; j < randomInt(5); j++) {
              await dbA.insert(
                defTableActs,
                {
                  defFkActsMemId.name: insertedMemId,
                  defColActsStart.name: start,
                  defColActsStartIsAllDay.name: 0,
                  defColActsEnd.name: now,
                  defColActsEndIsAllDay.name: 0,
                  defColCreatedAt.name: zeroDate,
                },
              );
            }
          }
        });

        testWidgets(
          ": show chart",
          (widgetTester) async {
            await showMemListPage(widgetTester);

            await widgetTester.tap(find.text(insertedMemName));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byIcon(Icons.show_chart));
            await widgetTester.pumpAndSettle();

            expect(true, isTrue);
          },
        );
      });

      group(': MemListPage', () {
        testWidgets(': start & finish act.', (widgetTester) async {
          await showMemListPage(widgetTester);

          expect(startIconFinder, findsNWidgets(2));
          expect(stopIconFinder, findsNothing);

          await widgetTester.tap(startIconFinder.at(1));
          await widgetTester.pump();

          expect(
            (widgetTester.widget(find.byType(Text).at(2)) as Text).data,
            '00:00:00',
          );
          expect(startIconFinder, findsOneWidget);
          expect(stopIconFinder, findsOneWidget);
          await widgetTester.pumpAndSettle(elapsePeriod);

          expect(find.text('00:00:00'), findsNothing);
          await widgetTester.tap(startIconFinder);
          await widgetTester.pumpAndSettle();

          expect(startIconFinder, findsNothing);
          expect(stopIconFinder, findsNWidgets(2));

          await widgetTester.tap(stopIconFinder.at(0));
          await widgetTester.pumpAndSettle();

          expect(stopIconFinder, findsOneWidget);
          expect(startIconFinder, findsOneWidget);
        });
      });
    });
