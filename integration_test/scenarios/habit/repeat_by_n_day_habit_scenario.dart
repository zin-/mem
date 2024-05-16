import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/components/mem/mem_name.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/mems/detail/fab.dart';
import 'package:mem/mems/detail/notifications/mem_notifications_view.dart';
import 'package:mem/mems/detail/notifications/mem_repeat_by_n_day_notification_view.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/notifications/schedule_client.dart';
import 'package:mem/values/durations.dart';

import '../helpers.dart';

const _name = 'Repeat by n day habit scenario';

void main() => group(
      _name,
      () {
        late final DatabaseAccessor dbA;
        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
        });
        setUp(() async {
          ScheduleClient.resetSingleton();
          await clearAllTestDatabaseRows(databaseDefinition);
        });

        int insertedMemId = 0;

        group(": Show", () {
          const insertedMemName = "$_name - mem name - inserted";
          const insertedMemRepeatByNDay = 2;

          setUp(() async {
            insertedMemId = await dbA.insert(
              defTableMems,
              {
                defColMemsName.name: insertedMemName,
                defColCreatedAt.name: zeroDate,
              },
            );
            await dbA.insert(
              defTableMemNotifications,
              {
                defFkMemNotificationsMemId.name: insertedMemId,
                defColMemNotificationsType.name:
                    MemNotificationType.repeat.name,
                defColMemNotificationsTime.name: 1,
                defColMemNotificationsMessage.name: "never",
                defColCreatedAt.name: zeroDate,
              },
            );
            await dbA.insert(
              defTableMemNotifications,
              {
                defFkMemNotificationsMemId.name: insertedMemId,
                defColMemNotificationsType.name:
                    MemNotificationType.repeatByNDay.name,
                defColMemNotificationsTime.name: insertedMemRepeatByNDay,
                defColMemNotificationsMessage.name: "never",
                defColCreatedAt.name: zeroDate,
              },
            );
          });

          testWidgets(
            ": on saved.",
            (widgetTester) async {
              await runApplication();
              await widgetTester.pumpAndSettle();

              await widgetTester.tap(find.text(insertedMemName));
              await widgetTester.pumpAndSettle(defaultTransitionDuration);

              expect(
                widgetTester
                    .widget<Text>(
                      find.descendant(
                          of: find.byKey(keyMemNotificationsView),
                          matching: find.byType(Text)),
                    )
                    .data,
                "12:00 AM every $insertedMemRepeatByNDay days",
              );

              await widgetTester.tap(
                find.descendant(
                  of: find.byKey(keyMemNotificationsView),
                  matching: find.byIcon(Icons.edit),
                ),
              );
              await widgetTester.pumpAndSettle(defaultTransitionDuration);

              expect(
                widgetTester
                    .widget<TextFormField>(
                      find.descendant(
                        of: find.byKey(keyMemRepeatByNDayNotification),
                        matching: find.byType(TextFormField),
                      ),
                    )
                    .initialValue,
                insertedMemRepeatByNDay.toString(),
              );
            },
          );
        });

        testWidgets(
          ": Save",
          (widgetTester) async {
            final testStart = DateTime.now();
            var expectedSavedMemId = 1;

            int alarmServiceStartCount = 0;
            int alarmCancelCount = 0;
            int alarmPeriodicCount = 0;
            widgetTester.setMockAndroidAlarmManager([
              (message) async {
                expect(message.method, equals('AlarmService.start'));
                expect(
                    message.arguments,
                    orderedEquals([
                      isNotNull,
                    ]));
                alarmServiceStartCount++;
                return true;
              },
              (message) async {
                expect(message.method, equals('Alarm.cancel'));
                expect(
                    message.arguments,
                    orderedEquals(
                        [equals(memStartNotificationId(expectedSavedMemId))]));
                alarmCancelCount++;
                return false;
              },
              (message) async {
                expect(message.method, equals('Alarm.cancel'));
                expect(
                    message.arguments,
                    orderedEquals(
                        [equals(memEndNotificationId(expectedSavedMemId))]));
                alarmCancelCount++;
                return false;
              },
              (message) async {
                expect(message.method, equals('Alarm.periodic'));
                expect(message.arguments[0],
                    equals(memRepeatedNotificationId(expectedSavedMemId)));
                expect(message.arguments[1], isFalse);
                expect(message.arguments[2], isFalse);
                expect(message.arguments[3], isFalse);
                expect(message.arguments[4],
                    greaterThan(testStart.millisecondsSinceEpoch));
                expect(message.arguments[5],
                    const Duration(days: 1).inMilliseconds);
                expect(message.arguments[6], isFalse);
                expect(message.arguments[7], isNotNull);
                expect(
                    message.arguments[8],
                    equals({
                      memIdKey: expectedSavedMemId,
                      notificationTypeKey: NotificationType.repeat.name
                    }));
                alarmPeriodicCount++;
                return false;
              },
            ]);

            await runApplication();
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(newMemFabFinder);
            await widgetTester.pumpAndSettle();
            const enteringMemName = "$_name: Save - entering - mem name";
            await widgetTester.enterText(
              find.byKey(keyMemName),
              enteringMemName,
            );

            final notificationAddFinder = find.descendant(
              of: find.byKey(keyMemNotificationsView),
              matching: find.byIcon(Icons.notification_add),
            );
            await widgetTester.tap(
              notificationAddFinder,
            );
            await widgetTester.pumpAndSettle(defaultTransitionDuration);

            await widgetTester.tap(timeIconFinder);
            await widgetTester.pump();
            await widgetTester.tap(okFinder);
            await widgetTester.pump();

            const enteringNDay = 3;
            await widgetTester.enterText(
              find.descendant(
                  of: find.byKey(keyMemRepeatByNDayNotification),
                  matching: find.byType(TextFormField)),
              enteringNDay.toString(),
            );

            await widgetTester.pageBack();
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.byKey(keySaveMemFab));
            await widgetTester.pumpAndSettle();

            final savedMem = (await dbA.select(
              defTableMems,
              where: "${defColMemsName.name} = ?",
              whereArgs: [enteringMemName],
            ))
                .single;
            final savedMemNotification = (await dbA.select(
              defTableMemNotifications,
              where: "${defFkMemNotificationsMemId.name} = ?"
                  " AND ${defColMemNotificationsType.name} = ?"
                  " AND ${defColMemNotificationsTime.name} = ?",
              whereArgs: [
                savedMem[defPkId.name],
                MemNotificationType.repeatByNDay.name,
                enteringNDay,
              ],
            ))
                .single;
            expect(
              savedMemNotification[defColMemNotificationsTime.name],
              enteringNDay,
            );

            if (defaultTargetPlatform == TargetPlatform.android) {
              expect(alarmServiceStartCount, equals(1));
              expect(alarmCancelCount, equals(2));
              expect(alarmPeriodicCount, equals(1));
              widgetTester.clearMockAndroidAlarmManager();
            } else {
              expect(alarmServiceStartCount, equals(0));
              expect(alarmCancelCount, equals(0));
              expect(alarmPeriodicCount, equals(0));
            }
          },
        );
      },
    );
