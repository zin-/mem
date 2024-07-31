import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/components/timer.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';

import '../helpers.dart';

const _name = "MemListPage scenario";

void main() => group(
      _name,
      () {
        const insertedMemNameBase = '$_name: inserted mem - name';
        const memWithActiveName = "$insertedMemNameBase - active";
        const plainMemName = "$insertedMemNameBase - plain";

        late final DatabaseAccessor dbA;

        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
        });

        int? insertedMemId;

        setUp(() async {
          await clearAllTestDatabaseRows(databaseDefinition);

          insertedMemId = await dbA.insert(
            defTableMems,
            {
              defColMemsName.name: memWithActiveName,
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
                  '$_name: mem notification message',
              defColCreatedAt.name: zeroDate,
            },
          );

          await dbA.insert(defTableMems, {
            defColMemsName.name: plainMemName,
            defColCreatedAt.name: zeroDate,
          });

          dbA.insert(defTableActs, {
            defFkActsMemId.name: insertedMemId,
            defColActsStart.name: zeroDate,
            defColActsStartIsAllDay.name: false,
            defColCreatedAt.name: zeroDate,
          });
        });

        group(
          'show',
          () {
            const memWithStartName = "$insertedMemNameBase - start";
            const memWithAfterStartName = "$insertedMemNameBase - after start";
            const memWithEveryDayName = "$insertedMemNameBase - every day";
            const memWithTomorrowDayOfWeekName =
                "$insertedMemNameBase - tomorrow day of week";
            const memWithTodayFinishedActName =
                "$insertedMemNameBase - today finished act";

            final now = DateTime.now();

            setUp(() async {
              await dbA.insert(defTableMems, {
                defColMemsName.name: memWithStartName,
                defColMemsStartOn.name: now,
                defColCreatedAt.name: zeroDate,
              });
              final memWithAfterStartId = await dbA.insert(defTableMems, {
                defColMemsName.name: memWithAfterStartName,
                defColCreatedAt.name: zeroDate,
              });
              await dbA.insert(defTableMemNotifications, {
                defFkMemNotificationsMemId.name: memWithAfterStartId,
                defColMemNotificationsTime.name: 3600,
                defColMemNotificationsType.name:
                    MemNotificationType.afterActStarted.name,
                defColMemNotificationsMessage.name: "",
                defColCreatedAt.name: zeroDate,
              });
              final memWithEveryDayId = await dbA.insert(defTableMems, {
                defColMemsName.name: memWithEveryDayName,
                defColCreatedAt.name: zeroDate,
              });
              await dbA.insert(defTableMemNotifications, {
                defFkMemNotificationsMemId.name: memWithEveryDayId,
                defColMemNotificationsTime.name: 1,
                defColMemNotificationsType.name:
                    MemNotificationType.repeatByNDay.name,
                defColMemNotificationsMessage.name: "",
                defColCreatedAt.name: zeroDate,
              });
              final memWithTomorrowDayOfWeekId =
                  await dbA.insert(defTableMems, {
                defColMemsName.name: memWithTomorrowDayOfWeekName,
                defColCreatedAt.name: zeroDate,
              });
              await dbA.insert(defTableMemNotifications, {
                defFkMemNotificationsMemId.name: memWithTomorrowDayOfWeekId,
                defColMemNotificationsTime.name:
                    now.add(const Duration(days: 1)).weekday,
                defColMemNotificationsType.name:
                    MemNotificationType.repeatByDayOfWeek.name,
                defColMemNotificationsMessage.name: "",
                defColCreatedAt.name: zeroDate,
              });
              final memWithTodayFinishedActId = await dbA.insert(defTableMems, {
                defColMemsName.name: memWithTodayFinishedActName,
                defColCreatedAt.name: zeroDate,
              });
              await dbA.insert(defTableMemNotifications, {
                defFkMemNotificationsMemId.name: memWithTodayFinishedActId,
                defColMemNotificationsTime.name: 1,
                defColMemNotificationsType.name:
                    MemNotificationType.repeatByNDay.name,
                defColMemNotificationsMessage.name: "",
                defColCreatedAt.name: zeroDate,
              });
              dbA.insert(defTableActs, {
                defFkActsMemId.name: memWithTodayFinishedActId,
                defColActsStart.name: now,
                defColActsStartIsAllDay.name: false,
                defColActsEnd.name: now,
                defColActsEndIsAllDay.name: false,
                defColCreatedAt.name: zeroDate,
              });
            });

            testWidgets(
              'sorted.',
              (widgetTester) async {
                widgetTester.ignoreMockMethodCallHandler(
                    MethodChannelMock.permissionHandler);
                widgetTester.ignoreMockMethodCallHandler(
                    MethodChannelMock.flutterLocalNotifications);

                await runApplication();
                await widgetTester.pumpAndSettle(waitSideEffectDuration);

                expect(widgetTester.textAt(0).data, equals(memWithActiveName));
                expect(widgetTester.textAt(3).data, equals(memWithStartName));
                expect(
                    widgetTester.textAt(6).data, equals(memWithEveryDayName));
                expect(widgetTester.textAt(7).data,
                    equals(memWithTomorrowDayOfWeekName));
                expect(widgetTester.textAt(9).data,
                    equals(memWithTodayFinishedActName));
                expect(widgetTester.textAt(10).data, equals(plainMemName));
                expect(widgetTester.textAt(11).data,
                    equals(memWithAfterStartName));
              },
            );
          },
        );

        group(
          'act',
          () {
            testWidgets(
              'start.',
              // 時間に関するテストなので3回までリトライ可能とする
              retry: 3,
              (widgetTester) async {
                widgetTester.ignoreMockMethodCallHandler(
                    MethodChannelMock.flutterLocalNotifications);

                await runApplication();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(startIconFinder);
                await widgetTester.pumpAndSettle();

                expect(widgetTester.widget<Text>(find.byType(Text).at(1)).data,
                    "00:00:00");

                expect(startIconFinder, findsNothing);
                expect(stopIconFinder, findsNWidgets(2));
                await widgetTester.pumpAndSettle(elapsePeriod * 2);

                expect(find.text("00:00:00"), findsNothing);
              },
            );

            testWidgets(
              'finish.',
              (widgetTester) async {
                widgetTester.ignoreMockMethodCallHandler(
                    MethodChannelMock.flutterLocalNotifications);

                await runApplication();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(stopIconFinder);
                await widgetTester.pump(waitSideEffectDuration);

                expect(startIconFinder, findsNWidgets(2));
                expect(stopIconFinder, findsNothing);
              },
            );
          },
        );
      },
    );
