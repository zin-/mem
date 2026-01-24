import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mems/mem_name.dart';

import 'package:mem/features/acts/list/duration.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:mem/framework/database/accessor.dart';
// import 'package:mem/values/durations.dart';

import '../helpers.dart';

const _name = "ActListPage scenario";

void main() => group(_name, () {
      const oneMin = Duration(minutes: 1);
      const insertedMemName = '$_name: inserted mem - name';
      const insertedMemWithActiveActName = '$insertedMemName - with active act';

      final oneMinDate = zeroDate.add(oneMin);

      late final DriftDatabaseAccessor dbA;
      late final int insertedMemId;
      late final int insertedMemWithActiveActId;

      setUpAll(() async {
        dbA = await openTestDatabase(databaseDefinition);
        await clearAllTestDatabaseRows(databaseDefinition);

        insertedMemId = await dbA.insert(defTableMems, {
          defColMemsName.name: insertedMemName,
          defColCreatedAt.name: zeroDate
        });
        insertedMemWithActiveActId = await dbA.insert(defTableMems, {
          defColMemsName.name: insertedMemWithActiveActName,
          defColCreatedAt.name: zeroDate
        });

        await dbA.insert(defTableTargets, {
          defFkTargetMemId.name: insertedMemId,
          defColTargetType.name: TargetType.equalTo.name,
          defColTargetUnit.name: TargetUnit.count.name,
          defColTargetValue.name: 1,
          defColTargetPeriod.name: Period.aDay.name,
          defColCreatedAt.name: zeroDate
        });
        await dbA.insert(defTableTargets, {
          defFkTargetMemId.name: insertedMemWithActiveActId,
          defColTargetType.name: TargetType.lessThan.name,
          defColTargetUnit.name: TargetUnit.time.name,
          defColTargetValue.name: oneMin.inSeconds,
          defColTargetPeriod.name: Period.all.name,
          defColCreatedAt.name: zeroDate
        });
      });
      setUp(() async {
        await dbA.delete(defTableActs);

        await dbA.insert(defTableActs, {
          defFkActsMemId.name: insertedMemId,
          defColActsStart.name: zeroDate,
          defColActsStartIsAllDay.name: 0,
          defColActsEnd.name: oneMinDate,
          defColActsEndIsAllDay.name: 0,
          defColCreatedAt.name: zeroDate
        });

        await dbA.insert(defTableActs, {
          defFkActsMemId.name: insertedMemWithActiveActId,
          defColActsStart.name: zeroDate,
          defColActsStartIsAllDay.name: 0,
          defColActsEnd.name: null,
          defColActsEndIsAllDay.name: null,
          defColCreatedAt.name: zeroDate
        });
      });

      group("Show inserted acts", () {
        // testWidgets(": by Mem.", (widgetTester) async {
        //   await runApplication();
        //   await widgetTester.pumpAndSettle();
        //   await widgetTester.tap(find.text(insertedMemName));
        //   await widgetTester.pumpAndSettle();
        //   await widgetTester.tap(startIconFinder);
        //   await widgetTester.pumpAndSettle();
        //   await widgetTester.tap(find.byIcon(Icons.numbers));
        //   await widgetTester.pumpAndSettle();

        //   expect(widgetTester.textAt(0).data, equals(insertedMemName));
        //   expect(widgetTester.textAt(1).data, equals(dateText(zeroDate)));
        //   expect(widgetTester.textAt(2).data, equals("1"));
        //   expect(widgetTester.textAt(3).data, equals(oneMin.format()));
        //   expect(widgetTester.textAt(4).data, equals(timeText(zeroDate)));
        //   expect(widgetTester.textAt(5).data, equals("~"));
        //   expect(widgetTester.textAt(6).data, equals(timeText(oneMinDate)));

        //   expect(startIconFinder, findsOneWidget);
        //   expect(stopIconFinder, findsNothing);
        // });

        group("All", () {
          testWidgets('Time.', (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byIcon(Icons.playlist_play));
            await widgetTester.pumpAndSettle();

            expect(startIconFinder, findsNothing);
            expect(stopIconFinder, findsNothing);
            expect(widgetTester.textAt(0).data, equals("All"));
            expect(widgetTester.textAt(1).data, equals(dateText(zeroDate)));
            expect(widgetTester.textAt(2).data, equals("2"));
            expect(widgetTester.textAt(3).data, equals(oneMin.format()));
            // zeroDateからの時間になるのでテストしない
            // expect(widgetTester.textAt(4).data, equals(oneMin.format()));
            expect(widgetTester.textAt(5).data, equals(" / "));
            expect(
              widgetTester.textAt(6).data,
              equals(Duration.zero.formatHHmm()),
            );
            expect(widgetTester.textAt(7).data, equals(" / "));
            expect(widgetTester.textAt(8).data, equals("0:01"));
            expect(widgetTester.textAt(9).data, equals("1"));
            expect(
              widgetTester.textAt(10).data,
              equals(insertedMemWithActiveActName),
            );
            expect(widgetTester.textAt(11).data, equals(oneMin.formatHHmm()));
            expect(widgetTester.textAt(12).data, equals("1"));
            expect(widgetTester.textAt(13).data, equals(" / "));
            expect(widgetTester.textAt(14).data, equals("1"));
            expect(widgetTester.textAt(15).data, equals(insertedMemName));
          });

          testWidgets('Count.', (widgetTester) async {
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
            expect(widgetTester.textAt(1).data, equals(dateText(zeroDate)));
            expect(widgetTester.textAt(2).data, equals("2"));
            expect(widgetTester.textAt(3).data, equals(oneMin.format()));
            expect(widgetTester.textAt(4).data, equals(timeText(zeroDate)));
            expect(widgetTester.textAt(5).data, equals("~"));
            expect(
              widgetTester.textAt(6).data,
              equals(insertedMemWithActiveActName),
            );
            expect(widgetTester.textAt(7).data, equals(timeText(zeroDate)));
            expect(widgetTester.textAt(8).data, equals("~"));
            expect(widgetTester.textAt(9).data, equals(timeText(oneMinDate)));
            expect(widgetTester.textAt(10).data, equals(insertedMemName));
          });

          testWidgets('Month view.', (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.byIcon(Icons.playlist_play));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.byIcon(Icons.calendar_view_month));
            await widgetTester.pumpAndSettle();

            expect(widgetTester.textAt(0).data, equals("All"));
            expect(widgetTester.textAt(1).data, equals("January 0"));
            expect(widgetTester.textAt(2).data, equals("2"));
            expect(widgetTester.textAt(3).data, equals(oneMin.format()));
            // zeroDateからの時間になるのでテストしない
            // expect(widgetTester.textAt(4).data, equals(oneMin.format()));
            expect(widgetTester.textAt(5).data, equals(" / "));
            expect(
              widgetTester.textAt(6).data,
              equals(Duration.zero.formatHHmm()),
            );
            expect(widgetTester.textAt(7).data, equals(" / "));
            expect(widgetTester.textAt(8).data, equals("0:01"));
            expect(widgetTester.textAt(9).data, equals("1"));
            expect(
              widgetTester.textAt(10).data,
              equals(insertedMemWithActiveActName),
            );
            expect(widgetTester.textAt(11).data, equals(oneMin.formatHHmm()));
            expect(widgetTester.textAt(12).data, equals("1"));
            expect(widgetTester.textAt(13).data, equals(" / "));
            expect(widgetTester.textAt(14).data, equals("1"));
            expect(widgetTester.textAt(15).data, equals(insertedMemName));
          });
        });

        group(": many acts", () {
          const days = 30;
          const numberOfActsByDate = 3;

          setUp(() async {
            await dbA.delete(defTableActs);

            for (var j = 0; j < days; j++) {
              for (var i = 0; i < numberOfActsByDate; i++) {
                final start =
                    zeroDate.add(Duration(days: j)).add(Duration(minutes: i));
                final end = start.add(oneMin);

                await dbA.insert(defTableActs, {
                  defFkActsMemId.name: insertedMemId,
                  defColActsStart.name: start,
                  defColActsStartIsAllDay.name: 0,
                  defColActsEnd.name: end,
                  defColActsEndIsAllDay.name: 0,
                  defColCreatedAt.name: zeroDate
                });
              }
            }
          });

          testWidgets(': infinite scroll.', (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.byIcon(Icons.playlist_play));
            await widgetTester.pumpAndSettle();

            final noOnInitialItemFinder = find.text("1/15/0");
            final earliestItemFinder = find.text("1/1/0");

            expect(noOnInitialItemFinder, findsNothing);
            expect(earliestItemFinder, findsNothing);

            final listFinder = find.byType(Scrollable);

            await widgetTester.scrollUntilVisible(noOnInitialItemFinder, 500.0,
                scrollable: listFinder);

            expect(noOnInitialItemFinder, findsOneWidget);
            expect(earliestItemFinder, findsNothing);

            await widgetTester.scrollUntilVisible(earliestItemFinder, 500.0,
                scrollable: listFinder);

            expect(noOnInitialItemFinder, findsNothing);
            expect(earliestItemFinder, findsOneWidget);
          });
        });
      });

      // group("By Mem", () {
      //   // Future<void> showActListPage(WidgetTester widgetTester) async {
      //   //   await runApplication();
      //   //   await widgetTester.pumpAndSettle();

      //   //   await widgetTester.tap(find.text(insertedMemName));
      //   //   await widgetTester.pumpAndSettle();

      //   //   await widgetTester.tap(startIconFinder);
      //   //   await widgetTester.pumpAndSettle();

      //   //   await widgetTester.tap(find.byIcon(Icons.numbers));
      //   //   await widgetTester.pumpAndSettle();
      //   // }

      //   // group(
      //   //   ': actions',
      //   //   () {
      //   //     testWidgets(
      //   //       ': start.',
      //   //       (widgetTester) async {
      //   //         widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
      //   //         widgetTester.ignoreMockMethodCallHandler(
      //   //             MethodChannelMock.permissionHandler);

      //   //         await runApplication();
      //   //         await widgetTester.pumpAndSettle();

      //   //         await widgetTester.showActListPageOf(insertedMemName);

      //   //         await widgetTester.tap(find.byIcon(Icons.numbers));
      //   //         await widgetTester.pump();

      //   //         final startTime = DateTime.now();
      //   //         await widgetTester.tap(startIconFinder);
      //   //         await widgetTester.pumpAndSettle();

      //   //         expect(startIconFinder, findsNothing);
      //   //         expect(stopIconFinder, findsOneWidget);
      //   //         expect(
      //   //           widgetTester.textAt(4).data,
      //   //           equals(timeText(startTime)),
      //   //         );

      //   //         final acts = await dbA.select(
      //   //           defTableActs,
      //   //           where: 'mems_id = ?',
      //   //           whereArgs: [insertedMemId],
      //   //         );
      //   //         expect(acts, hasLength(2));
      //   //         expect(acts[1][defColActsEnd.name], isNull);
      //   //         expect(acts[1][defColActsEndIsAllDay.name], isNull);
      //   //       },
      //   //     );

      //   //     testWidgets(
      //   //       ': finish.',
      //   //       (widgetTester) async {
      //   //         widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
      //   //         widgetTester.ignoreMockMethodCallHandler(
      //   //             MethodChannelMock.permissionHandler);

      //   //         await runApplication();
      //   //         await widgetTester.pumpAndSettle();

      //   //         await widgetTester.showActListPageOf(
      //   //           insertedMemWithActiveActName,
      //   //         );

      //   //         await widgetTester.tap(find.byIcon(Icons.numbers));
      //   //         await widgetTester.pump();

      //   //         final stopTime = DateTime.now();
      //   //         await widgetTester.tap(stopIconFinder);
      //   //         await widgetTester.pumpAndSettle();

      //   //         expect(stopIconFinder, findsNothing);
      //   //         expect(startIconFinder, findsOneWidget);
      //   //         expect(
      //   //           widgetTester.textAt(6).data,
      //   //           equals(timeText(stopTime)),
      //   //         );

      //   //         final acts = await dbA.select(
      //   //           defTableActs,
      //   //           where: 'mems_id = ?',
      //   //           whereArgs: [insertedMemWithActiveActId],
      //   //         );
      //   //         expect(acts, hasLength(1));
      //   //         expect(acts[0][defColActsEnd.name], isNotNull);
      //   //         expect(acts[0][defColActsEndIsAllDay.name], isNotNull);
      //   //       },
      //   //     );
      //   //   },
      //   // );

      //   // group('Edit act', () {
      //   //   setUp(() async {
      //   //     await dbA.insert(defTableActs, {
      //   //       defFkActsMemId.name: insertedMemId,
      //   //       defColActsStart.name: zeroDate,
      //   //       defColActsStartIsAllDay.name: 0,
      //   //       defColCreatedAt.name: zeroDate
      //   //     });
      //   //   });

      //   //   // testWidgets('[flaky]Save.', (widgetTester) async {
      //   //   //   widgetTester.ignoreMockMethodCallHandler(
      //   //   //       MethodChannelMock.permissionHandler);
      //   //   //   widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
      //   //   //   widgetTester.ignoreMockMethodCallHandler(
      //   //   //       MethodChannelMock.flutterLocalNotifications);

      //   //   //   await showActListPage(widgetTester);

      //   //   //   await widgetTester.longPress(find.text(timeText(zeroDate)).at(0));
      //   //   //   await widgetTester.pumpAndSettle();

      //   //   //   await widgetTester.tap(find.byType(Switch).at(1));
      //   //   //   await widgetTester.pump();

      //   //   //   final pickedDate = DateTime.now();
      //   //   //   await widgetTester.tap(find.text('OK'));
      //   //   //   await widgetTester.pump();

      //   //   //   await widgetTester.tap(find.byIcon(Icons.save_alt));
      //   //   //   await widgetTester.pumpAndSettle(waitSideEffectDuration);

      //   //   //   expect(widgetTester.textAt(0).data, equals(insertedMemName));
      //   //   //   expect(widgetTester.textAt(1).data, equals(dateText(zeroDate)));
      //   //   //   expect(widgetTester.textAt(2).data, equals("2"));
      //   //   //   expect(widgetTester.textAt(3).data, isNotNull);
      //   //   //   expect(widgetTester.textAt(4).data, equals(timeText(zeroDate)));
      //   //   //   expect(widgetTester.textAt(5).data, equals("~"));
      //   //   //   expect(widgetTester.textAt(6).data, equals(timeText(pickedDate)));
      //   //   //   expect(widgetTester.textAt(7).data, equals(timeText(zeroDate)));
      //   //   //   expect(widgetTester.textAt(8).data, equals("~"));
      //   //   //   expect(widgetTester.textAt(9).data, equals(timeText(oneMinDate)));

      //   //   //   await widgetTester.longPress(find.text(timeText(zeroDate)).at(1));
      //   //   //   await widgetTester.pumpAndSettle(defaultTransitionDuration);

      //   //   //   await widgetTester.tap(find.byIcon(Icons.clear).at(1));
      //   //   //   await widgetTester.pumpAndSettle();

      //   //   //   await widgetTester.tap(find.byIcon(Icons.save_alt));
      //   //   //   await widgetTester.pumpAndSettle(waitSideEffectDuration);

      //   //   //   expect(widgetTester.textAt(0).data, equals(insertedMemName));
      //   //   //   expect(widgetTester.textAt(1).data, equals(dateText(zeroDate)));
      //   //   //   expect(widgetTester.textAt(2).data, equals("2"));
      //   //   //   expect(widgetTester.textAt(3).data, isNotNull);
      //   //   //   expect(widgetTester.textAt(4).data, equals(timeText(zeroDate)));
      //   //   //   expect(widgetTester.textAt(5).data, equals("~"));
      //   //   //   expect(widgetTester.textAt(6).data, equals(timeText(zeroDate)));
      //   //   //   expect(widgetTester.textAt(7).data, equals("~"));
      //   //   //   expect(widgetTester.textAt(8).data, equals(timeText(pickedDate)));
      //   //   // });

      //   //   // testWidgets('Cancel.', (widgetTester) async {
      //   //   //   widgetTester.ignoreMockMethodCallHandler(
      //   //   //       MethodChannelMock.permissionHandler);
      //   //   //   widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
      //   //   //   widgetTester.ignoreMockMethodCallHandler(
      //   //   //       MethodChannelMock.flutterLocalNotifications);

      //   //   //   await showActListPage(widgetTester);

      //   //   //   await widgetTester.longPress(find.text(timeText(zeroDate)).at(0));
      //   //   //   await widgetTester.pumpAndSettle();

      //   //   //   await widgetTester.tap(find.byIcon(Icons.clear));
      //   //   //   await widgetTester.pumpAndSettle();

      //   //   //   expect(widgetTester.textAt(0).data, equals(insertedMemName));
      //   //   //   expect(widgetTester.textAt(1).data, equals(dateText(zeroDate)));
      //   //   //   expect(widgetTester.textAt(2).data, equals("2"));
      //   //   //   expect(widgetTester.textAt(3).data, equals(oneMin.format()));
      //   //   //   expect(widgetTester.textAt(4).data, equals(timeText(zeroDate)));
      //   //   //   expect(widgetTester.textAt(5).data, equals("~"));
      //   //   //   expect(widgetTester.textAt(4).data, equals(timeText(zeroDate)));
      //   //   // });

      //   //   // testWidgets('Delete.', (widgetTester) async {
      //   //   //   widgetTester.ignoreMockMethodCallHandler(
      //   //   //       MethodChannelMock.permissionHandler);
      //   //   //   widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
      //   //   //   widgetTester.ignoreMockMethodCallHandler(
      //   //   //       MethodChannelMock.flutterLocalNotifications);

      //   //   //   await showActListPage(widgetTester);

      //   //   //   await widgetTester.longPress(find.text(timeText(zeroDate)).at(0));
      //   //   //   await widgetTester.pumpAndSettle();

      //   //   //   await widgetTester.tap(find.byIcon(Icons.delete));
      //   //   //   await widgetTester.pumpAndSettle();

      //   //   //   expect(widgetTester.textAt(0).data, equals(insertedMemName));
      //   //   //   expect(widgetTester.textAt(1).data, equals(dateText(zeroDate)));
      //   //   //   expect(widgetTester.textAt(2).data, equals("1"));
      //   //   //   expect(widgetTester.textAt(3).data, equals(oneMin.format()));
      //   //   //   expect(widgetTester.textAt(4).data, equals(timeText(zeroDate)));
      //   //   //   expect(widgetTester.textAt(5).data, equals("~"));
      //   //   //   expect(widgetTester.textAt(6).data, equals(timeText(oneMinDate)));
      //   //   // });
      //   // });
      // });

      testWidgets(": show MemDetailPage.", (widgetTester) async {
        widgetTester.ignoreMockMethodCallHandler(
            MethodChannelMock.flutterLocalNotifications);

        await runApplication();
        await widgetTester.pumpAndSettle();
        await widgetTester.tap(find.byIcon(Icons.playlist_play));
        await widgetTester.pumpAndSettle();

        await widgetTester.tap(find.byIcon(Icons.arrow_forward).at(1));
        await widgetTester.pumpAndSettle();

        expect(
          widgetTester
              .widget<TextFormField>(find.byKey(keyMemName))
              .initialValue,
          insertedMemName,
        );
      });
    });
