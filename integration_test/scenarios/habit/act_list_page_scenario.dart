import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/components/mem/mem_name.dart';

import 'package:mem/core/date_and_time/duration.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/values/durations.dart';

import '../helpers.dart';

const _name = "ActListPage scenario";

void main() => group(
      _name,
      () {
        const oneMin = Duration(minutes: 1);
        const insertedMemName = '$_name: inserted mem - name';

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

        group(
          ": show inserted acts",
          () {
            testWidgets(
              ": by Mem.",
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.text(insertedMemName));
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(startIconFinder);
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.byIcon(Icons.numbers));
                await widgetTester.pumpAndSettle();

                expect(widgetTester.textAt(0).data, equals(insertedMemName));
                expect(widgetTester.textAt(1).data, equals(dateText(zeroDate)));
                expect(widgetTester.textAt(2).data, equals("1"));
                expect(widgetTester.textAt(3).data, equals(oneMin.format()));
                expect(widgetTester.textAt(4).data, equals(timeText(zeroDate)));
                expect(widgetTester.textAt(5).data, equals("~"));
                expect(
                    widgetTester.textAt(6).data, equals(timeText(oneMinDate)));

                expect(startIconFinder, findsOneWidget);
                expect(stopIconFinder, findsNothing);
              },
            );

            group(
              ": All",
              () {
                testWidgets(
                  ': time.',
                  (widgetTester) async {
                    await runApplication();
                    await widgetTester.pumpAndSettle();

                    await widgetTester.tap(find.byIcon(Icons.playlist_play));
                    await widgetTester.pumpAndSettle();

                    expect(startIconFinder, findsNothing);
                    expect(stopIconFinder, findsNothing);
                    expect(widgetTester.textAt(0).data, equals("All"));
                    expect(widgetTester.textAt(1).data,
                        equals(dateText(zeroDate)));
                    expect(widgetTester.textAt(2).data, equals("1"));
                    expect(
                        widgetTester.textAt(3).data, equals(oneMin.format()));
                    expect(
                        widgetTester.textAt(4).data, equals(oneMin.format()));
                    expect(widgetTester.textAt(5).data, equals("1"));
                    expect(
                        widgetTester.textAt(6).data, equals(insertedMemName));
                  },
                );

                testWidgets(
                  ': count.',
                  (widgetTester) async {
                    await runApplication();
                    await widgetTester.pumpAndSettle();
                    await widgetTester.tap(find.byIcon(Icons.playlist_play));
                    await widgetTester.pumpAndSettle();

                    await widgetTester.tap(find.byIcon(Icons.numbers));
                    await widgetTester.pumpAndSettle();

                    expect(startIconFinder, findsNothing);
                    expect(stopIconFinder, findsNothing);
                    expect(find.byIcon(Icons.access_time), findsOneWidget);
                    expect(widgetTester.textAt(0).data, equals("All"));
                    expect(widgetTester.textAt(1).data,
                        equals(dateText(zeroDate)));
                    expect(widgetTester.textAt(2).data, equals("1"));
                    expect(
                        widgetTester.textAt(3).data, equals(oneMin.format()));
                    expect(widgetTester.textAt(4).data,
                        equals(timeText(zeroDate)));
                    expect(widgetTester.textAt(5).data, equals("~"));
                    expect(widgetTester.textAt(6).data,
                        equals(timeText(oneMinDate)));
                    expect(
                        widgetTester.textAt(7).data, equals(insertedMemName));
                  },
                );

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

                    expect(widgetTester.textAt(0).data, equals("All"));
                    expect(widgetTester.textAt(1).data, equals("January 0"));
                    expect(widgetTester.textAt(2).data, equals("1"));
                    expect(
                        widgetTester.textAt(3).data, equals(oneMin.format()));
                    expect(
                        widgetTester.textAt(4).data, equals(oneMin.format()));
                    expect(widgetTester.textAt(5).data, equals("1"));
                    expect(
                        widgetTester.textAt(6).data, equals(insertedMemName));
                  },
                );
              },
            );
          },
        );

        group(": by Mem", () {
          Future<void> showMemListPage(WidgetTester widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();
          }

          Future<void> showActListPage(WidgetTester widgetTester) async {
            await showMemListPage(widgetTester);

            await widgetTester.tap(find.text(insertedMemName));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(startIconFinder);
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byIcon(Icons.numbers));
            await widgetTester.pumpAndSettle();
          }

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
              expect(widgetTester.textAt(0).data, equals(insertedMemName));
              expect(widgetTester.textAt(1).data, equals(dateText(startTime)));
              expect(widgetTester.textAt(2).data, equals("1"));
              expect(
                  widgetTester.textAt(3).data, equals(Duration.zero.format()));
              expect(widgetTester.textAt(4).data, equals(timeText(startTime)));
              expect(widgetTester.textAt(5).data, equals("~"));
              expect(widgetTester.textAt(6).data, equals(dateText(zeroDate)));
              expect(widgetTester.textAt(7).data, equals("1"));
              expect(widgetTester.textAt(8).data, equals(oneMin.format()));
              expect(widgetTester.textAt(9).data, equals(timeText(zeroDate)));
              expect(widgetTester.textAt(10).data, equals("~"));
              expect(
                  widgetTester.textAt(11).data, equals(timeText(oneMinDate)));

              final stopTime = DateTime.now();
              await widgetTester.tap(stopIconFinder);
              await Future.delayed(defaultTransitionDuration);
              await widgetTester.pumpAndSettle(waitSideEffectDuration);

              expect(widgetTester.textAt(0).data, equals(insertedMemName));
              expect(widgetTester.textAt(1).data, equals(dateText(startTime)));
              expect(widgetTester.textAt(2).data, equals("1"));
              expect(widgetTester.textAt(3).data, isNotNull);
              expect(widgetTester.textAt(4).data, equals(timeText(startTime)));
              expect(widgetTester.textAt(5).data, equals("~"));
              expect(widgetTester.textAt(6).data, equals(timeText(stopTime)));
              expect(widgetTester.textAt(7).data, equals(dateText(zeroDate)));
              expect(widgetTester.textAt(8).data, equals("1"));
              expect(widgetTester.textAt(9).data, equals(oneMin.format()));
              expect(widgetTester.textAt(10).data, equals(timeText(zeroDate)));
              expect(widgetTester.textAt(11).data, equals("~"));
              expect(
                  widgetTester.textAt(12).data, equals(timeText(oneMinDate)));
              expect(stopIconFinder, findsNothing);

              final startTime2 = DateTime.now();
              await widgetTester.tap(startIconFinder);
              await Future.delayed(defaultTransitionDuration);
              await widgetTester.pumpAndSettle(waitSideEffectDuration);

              expect(widgetTester.textAt(0).data, equals(insertedMemName));
              expect(widgetTester.textAt(1).data, equals(dateText(startTime2)));
              expect(widgetTester.textAt(2).data, equals("2"));
              expect(widgetTester.textAt(3).data, isNotNull);
              expect(widgetTester.textAt(4).data, equals(timeText(startTime2)));
              expect(widgetTester.textAt(5).data, equals("~"));
              expect(widgetTester.textAt(6).data, equals(timeText(startTime)));
              expect(widgetTester.textAt(7).data, equals("~"));
              expect(widgetTester.textAt(8).data, equals(timeText(stopTime)));
              expect(widgetTester.textAt(9).data, equals(dateText(zeroDate)));
              expect(widgetTester.textAt(10).data, equals("1"));
              expect(widgetTester.textAt(11).data, equals(oneMin.format()));
              expect(widgetTester.textAt(12).data, equals(timeText(zeroDate)));
              expect(widgetTester.textAt(13).data, equals("~"));
              expect(
                  widgetTester.textAt(14).data, equals(timeText(oneMinDate)));
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

                expect(widgetTester.textAt(0).data, equals(insertedMemName));
                expect(widgetTester.textAt(1).data, equals(dateText(zeroDate)));
                expect(widgetTester.textAt(2).data, equals("2"));
                expect(widgetTester.textAt(3).data, isNotNull);
                expect(widgetTester.textAt(4).data, equals(timeText(zeroDate)));
                expect(widgetTester.textAt(5).data, equals("~"));
                expect(
                    widgetTester.textAt(6).data, equals(timeText(pickedDate)));
                expect(widgetTester.textAt(7).data, equals(timeText(zeroDate)));
                expect(widgetTester.textAt(8).data, equals("~"));
                expect(
                    widgetTester.textAt(9).data, equals(timeText(oneMinDate)));

                await widgetTester
                    .longPress(find.text(timeText(zeroDate)).at(1));
                await widgetTester.pumpAndSettle(defaultTransitionDuration);

                await widgetTester.tap(find.byIcon(Icons.clear).at(1));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.byIcon(Icons.save_alt));
                await widgetTester.pumpAndSettle(waitSideEffectDuration);

                expect(widgetTester.textAt(0).data, equals(insertedMemName));
                expect(widgetTester.textAt(1).data, equals(dateText(zeroDate)));
                expect(widgetTester.textAt(2).data, equals("2"));
                expect(widgetTester.textAt(3).data, isNotNull);
                expect(widgetTester.textAt(4).data, equals(timeText(zeroDate)));
                expect(widgetTester.textAt(5).data, equals("~"));
                expect(widgetTester.textAt(6).data, equals(timeText(zeroDate)));
                expect(widgetTester.textAt(7).data, equals("~"));
                expect(
                    widgetTester.textAt(8).data, equals(timeText(pickedDate)));
              },
            );

            testWidgets(': delete.', (widgetTester) async {
              await showActListPage(widgetTester);

              await widgetTester.longPress(find.text(timeText(zeroDate)).at(0));
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.byIcon(Icons.delete));
              await widgetTester.pumpAndSettle();

              expect(widgetTester.textAt(0).data, equals(insertedMemName));
              expect(widgetTester.textAt(1).data, equals(dateText(zeroDate)));
              expect(widgetTester.textAt(2).data, equals("1"));
              expect(widgetTester.textAt(3).data, equals(oneMin.format()));
              expect(widgetTester.textAt(4).data, equals(timeText(zeroDate)));
              expect(widgetTester.textAt(5).data, equals("~"));
              expect(widgetTester.textAt(6).data, equals(timeText(oneMinDate)));
            });
          });
        });

        testWidgets(
          ": show MemDetailPage.",
          (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.byIcon(Icons.playlist_play));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byIcon(Icons.arrow_forward));
            await widgetTester.pumpAndSettle();

            expect(
              widgetTester
                  .widget<TextFormField>(find.byKey(keyMemName))
                  .initialValue,
              insertedMemName,
            );
          },
        );
      },
    );
