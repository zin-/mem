import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/logger/log.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification_client.dart';
import 'package:mem/notifications/notification/type.dart';
import 'package:mem/notifications/notification_ids.dart';
import 'package:mem/settings/client.dart';
import 'package:mem/settings/preference.dart';
import 'package:mem/settings/keys.dart';
import 'package:settings_ui/settings_ui.dart';

import '../helpers.dart';

const _scenarioName = "Settings test";

void main() => group(
      ": $_scenarioName",
      () {
        LogService.initialize(
          Level.warning,
          const bool.fromEnvironment('CICD', defaultValue: false),
        );

        const numberOfMem = 100;
        const insertedMemName = '$_scenarioName: inserted - mem name';

        final insertedMemIds = List<int>.empty(growable: true);

        late final DatabaseAccessor dbA;

        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
        });

        setUp(() async {
          NotificationClient.resetSingleton();

          await clearAllTestDatabaseRows(databaseDefinition);

          for (var i = 0; i < numberOfMem; i++) {
            insertedMemIds.add(
              await dbA.insert(
                defTableMems,
                {
                  defColMemsName.name: "$insertedMemName: $i",
                  defColCreatedAt.name: zeroDate,
                },
              ),
            );
          }
        });

        testWidgets(
          'show page.',
          (widgetTester) async {
            widgetTester.clearAllMockMethodCallHandler();

            await runApplication();
            await widgetTester.pumpAndSettle();

            expect(find.byType(AppBar), findsOneWidget);

            await widgetTester.tap(drawerIconFinder);
            await widgetTester.pumpAndSettle();

            expect(find.byIcon(Icons.settings), findsOneWidget);
            await widgetTester.tap(find.text(l10n.settingsPageTitle));
            await widgetTester.pumpAndSettle();

            expect(find.text(l10n.settingsPageTitle), findsOneWidget);
            expect(find.byIcon(Icons.start), findsOneWidget);
            expect(find.text(l10n.startOfDayLabel), findsOneWidget);
            expect(find.byIcon(Icons.backup), findsOneWidget);
            expect(find.text(l10n.backupLabel), findsOneWidget);
            expect(find.byIcon(Icons.backup), findsOneWidget);
            expect(find.text(l10n.resetNotificationLabel), findsOneWidget);
          },
        );

        group(
          "Start of day",
          () {
            setUp(() async {
              await PreferenceClient().discard(startOfDayKey);
            });

            testWidgets(
              "pick start of day.",
              (widgetTester) async {
                await runApplication();
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(drawerIconFinder);
                await widgetTester.pumpAndSettle();
                await widgetTester.tap(find.text(l10n.settingsPageTitle));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(find.text(l10n.startOfDayLabel));
                await widgetTester.pumpAndSettle();

                await widgetTester.tap(okFinder);
                await widgetTester.pumpAndSettle();

                expect(
                  widgetTester
                      .widget<Text>(find
                          .descendant(
                            of: find.byType(SettingsTile),
                            matching: find.byType(Text),
                          )
                          .at(1))
                      .data,
                  timeText(zeroDate),
                );
                expect(
                  (await PreferenceClient().shipByKey(startOfDayKey)).value,
                  TimeOfDay.fromDateTime(zeroDate),
                );
              },
            );

            group(
              "with saved",
              () {
                final now = DateTime.now();
                setUp(() async {
                  await PreferenceClient().receive(Preference(
                    startOfDayKey,
                    TimeOfDay.fromDateTime(now),
                  ));
                });

                testWidgets(
                  "show saved.",
                  (widgetTester) async {
                    await runApplication();
                    await widgetTester.pumpAndSettle();

                    await widgetTester.tap(drawerIconFinder);
                    await widgetTester.pumpAndSettle();
                    await widgetTester.tap(find.text(l10n.settingsPageTitle));
                    await widgetTester.pumpAndSettle();

                    expect(
                      widgetTester
                          .widget<Text>(find
                              .descendant(
                                of: find.byType(SettingsTile),
                                matching: find.byType(Text),
                              )
                              .at(1))
                          .data,
                      timeText(now),
                    );
                  },
                );
              },
            );
          },
        );

        testWidgets(
          'Reset Notification',
          (widgetTester) async {
            widgetTester.ignoreMockMethodCallHandler(
                MethodChannelMock.permissionHandler);
            int alarmServiceStartCount = 0;
            int alarmCancelCount = 0;
            final cancelIds = insertedMemIds
                .map(
                  (e) => [
                    memStartNotificationId(e),
                    memEndNotificationId(e),
                    memRepeatedNotificationId(e),
                  ],
                )
                .flattened;
            widgetTester.setMockMethodCallHandler(
                MethodChannelMock.androidAlarmManager, [
              (m) async {
                expect(m.method, equals('AlarmService.start'));
                alarmServiceStartCount++;
                return true;
              },
              ...cancelIds.map((e) => (m) async {
                    expect(m.method, equals('Alarm.cancel'));
                    alarmCancelCount++;
                    return false;
                  }),
            ]);

            int initializeCount = 0;
            int getNotificationAppLaunchDetailsCount = 0;
            int cancelAllCount = 0;
            int deleteNotificationChannelCount = 0;
            widgetTester.setMockMethodCallHandler(
                MethodChannelMock.flutterLocalNotifications, [
              (m) async {
                expect(m.method, equals('initialize'));
                initializeCount++;
                return true;
              },
              (m) async {
                expect(m.method, equals('getNotificationAppLaunchDetails'));
                getNotificationAppLaunchDetailsCount++;
                return null;
              },
              (m) async {
                expect(m.method, equals('cancelAll'));
                cancelAllCount++;
                return null;
              },
              ...NotificationType.values.map(
                (e) => (m) async {
                  expect(m.method, equals('deleteNotificationChannel'));
                  deleteNotificationChannelCount++;
                  return null;
                },
              ),
            ]);

            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(drawerIconFinder);
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.text(l10n.settingsPageTitle));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.text(l10n.resetNotificationLabel));
            await widgetTester.pump();

            expect(find.byType(CircularProgressIndicator), findsOneWidget);

            var indicator = widgetTester
                .elementList(find.byType(CircularProgressIndicator));
            while (indicator.length == 1) {
              await widgetTester.pump();
              indicator = widgetTester
                  .elementList(find.byType(CircularProgressIndicator));
            }

            expect(find.byType(CircularProgressIndicator), findsNothing);
            expect(find.text(l10n.completeResetNotification), findsOneWidget);

            if (defaultTargetPlatform == TargetPlatform.android) {
              expect(alarmServiceStartCount, equals(1),
                  reason: 'alarmServiceStartCount');
              expect(alarmCancelCount, equals(300), reason: 'alarmCancelCount');
              expect(initializeCount, equals(1), reason: 'initializeCount');
              expect(getNotificationAppLaunchDetailsCount, equals(1),
                  reason: 'getNotificationAppLaunchDetailsCount');
              expect(cancelAllCount, equals(1), reason: 'cancelAllCount');
              expect(deleteNotificationChannelCount,
                  equals(NotificationType.values.length),
                  reason: 'deleteNotificationChannelCount');
            } else {
              expect(alarmServiceStartCount, equals(0),
                  reason: 'alarmServiceStartCount');
              expect(alarmCancelCount, equals(0), reason: 'alarmCancelCount');
              expect(initializeCount, equals(0), reason: 'initializeCount');
              expect(getNotificationAppLaunchDetailsCount, equals(0),
                  reason: 'getNotificationAppLaunchDetailsCount');
              expect(cancelAllCount, equals(0), reason: 'cancelAllCount');
              expect(deleteNotificationChannelCount, equals(0),
                  reason: 'deleteNotificationChannelCount');
            }

            widgetTester.clearAllMockMethodCallHandler();
          },
        );
      },
    );
