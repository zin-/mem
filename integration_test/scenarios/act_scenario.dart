import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/components/timer.dart';
import 'package:mem/core/date_and_time/duration.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/values/durations.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testActScenario();
}

const _scenarioName = 'Act scenario';

void testActScenario() => group(': $_scenarioName', () {
      const oneMin = Duration(minutes: 1);
      const insertedMemName = '$_scenarioName: inserted mem - name';

      final showActPageIconFinder = find.byIcon(Icons.play_arrow);
      final startIconFinder = find.byIcon(Icons.play_arrow);
      final stopIconFinder = find.byIcon(Icons.stop);
      final oneMinDate = zeroDate.add(oneMin);

      late final DatabaseAccessor dbA;
      late final int insertedMemId;

      setUpAll(() async {
        dbA = await openTestDatabase(databaseDefinition);
        await clearAllTestDatabaseRows(databaseDefinition);

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
            defColActsEnd.name: oneMinDate,
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
        group(": All", () {
          group(
            ": show inserted acts",
            () {
              testWidgets(': time.', (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.byIcon(Icons.playlist_play));
                await widgetTester.pumpAndSettle();

                expect(startIconFinder, findsNothing);
                expect(stopIconFinder, findsNothing);
                [
                  "All",
                  dateText(zeroDate),
                  "1",
                  oneMin.format(),
                  oneMin.format(),
                  "1",
                  insertedMemName,
                ].forEachIndexed((index, t) {
                  expect(
                    (widgetTester.widget(find.byType(Text).at(index)) as Text)
                        .data,
                    t,
                    reason: "Index is \"$index\".",
                  );
                });
              });

              testWidgets(': count.', (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.byIcon(Icons.playlist_play));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.byIcon(Icons.numbers));
                await widgetTester.pumpAndSettle();

                expect(startIconFinder, findsNothing);
                expect(stopIconFinder, findsNothing);
                expect(find.byIcon(Icons.access_time), findsOneWidget);
                [
                  "All",
                  dateText(zeroDate),
                  "1",
                  oneMin.format(),
                  timeText(zeroDate),
                  "~",
                  timeText(oneMinDate),
                  insertedMemName,
                ].forEachIndexed((index, t) {
                  expect(
                    (widgetTester.widget(find.byType(Text).at(index)) as Text)
                        .data,
                    t,
                    reason: "Index is \"$index\".",
                  );
                });
              });

              testWidgets(
                ': month view.',
                (widgetTester) async {
                  await runApplication();
                  await widgetTester.pumpAndSettle();
                  await widgetTester.tap(find.byIcon(Icons.playlist_play));
                  await widgetTester.pumpAndSettle();

                  await widgetTester
                      .tap(find.byIcon(Icons.calendar_view_month));
                  await widgetTester.pumpAndSettle();

                  [
                    equals("All"),
                    equals("January 0"),
                    equals("1"),
                    equals(oneMin.format()),
                    equals(oneMin.format()),
                    equals("1"),
                    insertedMemName,
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
            },
          );
        });

        group(": by Mem", () {
          Future<void> showActListPage(WidgetTester widgetTester) async {
            await showMemListPage(widgetTester);

            await widgetTester.tap(find.text(insertedMemName));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(showActPageIconFinder);
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byIcon(Icons.numbers));
            await widgetTester.pumpAndSettle();
          }

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
                  oneMin.format(),
                  timeText(zeroDate),
                  "~",
                  timeText(zeroDate),
                  "~",
                  timeText(oneMinDate),
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
              setMockLocalNotifications(widgetTester);

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
                Duration.zero.format(),
                timeText(startTime),
                "~",
                dateText(zeroDate),
                "1",
                oneMin.format(),
                timeText(zeroDate),
                "~",
                timeText(oneMinDate),
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
                isNotNull,
                timeText(startTime),
                "~",
                timeText(stopTime),
                dateText(zeroDate),
                "1",
                oneMin.format(),
                timeText(zeroDate),
                "~",
                timeText(oneMinDate),
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
                isNotNull,
                timeText(startTime2),
                "~",
                timeText(startTime),
                "~",
                timeText(stopTime),
                dateText(zeroDate),
                "1",
                oneMin.format(),
                timeText(zeroDate),
                "~",
                timeText(oneMinDate),
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

            testWidgets(
              ': save.',
              (widgetTester) async {
                await showActListPage(widgetTester);

                await widgetTester
                    .longPress(find.text(timeText(zeroDate)).at(0));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.byType(Switch).at(1));
                await widgetTester.pump();

                final pickedDate = DateTime.now();
                await widgetTester.tap(find.text('OK'));
                await widgetTester.pump();

                await widgetTester.tap(find.byIcon(Icons.save_alt));
                await widgetTester.pumpAndSettle(waitSideEffectDuration);

                [
                  insertedMemName,
                  dateText(zeroDate),
                  "2",
                  "skip",
                  timeText(zeroDate),
                  "~",
                  timeText(pickedDate),
                  timeText(zeroDate),
                  "~",
                  timeText(oneMinDate),
                ].forEachIndexed((index, expected) {
                  expect(
                    (widgetTester.widget(find.byType(Text).at(index)) as Text)
                        .data,
                    expected,
                    reason: "Index is \"$index\".",
                    skip: expected == "skip",
                  );
                });

                await widgetTester
                    .longPress(find.text(timeText(zeroDate)).at(1));
                await widgetTester.pumpAndSettle(defaultTransitionDuration);

                await widgetTester.tap(find.byIcon(Icons.clear).at(1));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.byIcon(Icons.save_alt));
                await widgetTester.pumpAndSettle(waitSideEffectDuration);

                [
                  insertedMemName,
                  dateText(zeroDate),
                  "2",
                  "skip",
                  timeText(zeroDate),
                  "~",
                  timeText(zeroDate),
                  "~",
                  timeText(pickedDate),
                ].forEachIndexed((index, expected) {
                  expect(
                    (widgetTester.widget(find.byType(Text).at(index)) as Text)
                        .data,
                    expected,
                    reason: "Index is \"$index\".",
                    skip: expected == "skip",
                  );
                });
              },
            );

            testWidgets(': delete.', (widgetTester) async {
              await showActListPage(widgetTester);

              await widgetTester.longPress(find.text(timeText(zeroDate)).at(0));
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.byIcon(Icons.delete));
              await widgetTester.pumpAndSettle();

              [
                insertedMemName,
                dateText(zeroDate),
                "1",
                oneMin.format(),
                timeText(zeroDate),
                "~",
                timeText(oneMinDate),
              ].forEachIndexed((index, expected) {
                expect(
                  (widgetTester.widget(find.byType(Text).at(index)) as Text)
                      .data,
                  expected,
                  reason: "Index is \"$index\".",
                  skip: expected == "skip",
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
          for (int i = 0; i < 34; i++) {
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

        testWidgets(": show chart", (widgetTester) async {
          await showMemListPage(widgetTester);

          await widgetTester.tap(find.text(insertedMemName));
          await widgetTester.pumpAndSettle();

          await widgetTester.tap(find.byIcon(Icons.show_chart));
          await widgetTester.pumpAndSettle();

          expect(true, isTrue);
        });
      });

      group(': MemListPage', () {
        setUp(() async {
          dbA.insert(defTableActs, {
            defFkActsMemId.name: insertedMemId,
            defColActsStart.name: zeroDate,
            defColActsStartIsAllDay.name: false,
            defColCreatedAt.name: zeroDate,
          });
        });

        testWidgets(
          ": start act.",
          (widgetTester) async {
            await showMemListPage(widgetTester);

            await widgetTester.tap(startIconFinder);
            await widgetTester.pumpAndSettle();

            expect(
              widgetTester.widget<Text>(find.byType(Text).at(3)).data,
              '00:00:00',
            );

            expect(startIconFinder, findsNothing);
            expect(stopIconFinder, findsNWidgets(2));
            await widgetTester.pumpAndSettle(elapsePeriod);

            expect(find.text('00:00:00'), findsNothing);
          },
        );

        testWidgets(": finish act.", (widgetTester) async {
          await showMemListPage(widgetTester);

          await widgetTester.tap(stopIconFinder);
          await widgetTester.pump();

          expect(startIconFinder, findsNWidgets(2));
          expect(stopIconFinder, findsNothing);
        });
      });
    });
