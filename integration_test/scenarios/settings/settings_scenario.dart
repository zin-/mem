import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_repository.dart';
import 'package:mem/features/acts/client.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/seconds_of_time_picker.dart';
import 'package:mem/features/logger/log.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mem/framework/notifications/notification/type.dart';
import 'package:mem/features/settings/preference/client.dart';
import 'package:mem/features/settings/preference/repository.dart';
import 'package:mem/features/settings/preference/preference.dart';
import 'package:mem/features/settings/preference/keys.dart';

import '../helpers.dart';

const _scenarioName = "Settings test";

void main() => group(_scenarioName, () {
      LogService(
        level: Level.verbose,
        enableSimpleLog:
            const bool.fromEnvironment('CICD', defaultValue: false),
      );

      const numberOfMem = 100;
      const insertedMemName = '$_scenarioName: inserted - mem name';

      late final DatabaseAccessor dbA;

      setUpAll(() async {
        dbA = await openTestDatabase(databaseDefinition);
      });

      setUp(() async {
        NotificationClient.resetSingleton();

        await clearAllTestDatabaseRows(databaseDefinition);
      });

      testWidgets('show page.', (widgetTester) async {
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
      });

      // FIXME そもそも時間指定の通知全体が動いていない
      // 　　https://github.com/zin-/mem/issues/478
      group("Notify after inactivity", skip: true, () {
        setUp(() async {
          await PreferenceRepository().discard(notifyAfterInactivity);
        });

        testWidgets("Show.", (widgetTester) async {
          await runApplication();
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(drawerIconFinder);
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(find.text(l10n.settingsPageTitle));
          await widgetTester.pumpAndSettle();

          final texts = widgetTester.widgetList<Text>(find.byType(Text));
          expect(
            texts.elementAt(2).data,
            equals(l10n.notifyAfterInactivityLabel),
          );
        });

        testWidgets("Save.", (widgetTester) async {
          widgetTester.clearAllMockMethodCallHandler();
          widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
          widgetTester
              .ignoreMockMethodCallHandler(MethodChannelMock.permissionHandler);

          int initializeCount = 0;
          int registerOneOffTaskCount = 0;
          widgetTester.setMockMethodCallHandler(
              MethodChannelMock.workmanagerForeground, [
            (m) async {
              expect(m.method, equals('initialize'));
              initializeCount++;
              return true;
            },
            (m) async {
              expect(m.method, equals('registerOneOffTask'));
              registerOneOffTaskCount++;
              return true;
            },
          ]);

          await runApplication();
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(drawerIconFinder);
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(find.text(l10n.settingsPageTitle));
          await widgetTester.pumpAndSettle();

          const secondsOfHour = 3600;
          final texts = widgetTester.widgetList<Text>(find.byType(Text));
          expect(
            texts.elementAt(3).data,
            isNot(equals(formatSecondsOfTime(secondsOfHour))),
          );

          await widgetTester.tap(find.text(l10n.notifyAfterInactivityLabel));
          await widgetTester.pumpAndSettle();
          await widgetTester.tap(find.text(l10n.okAction));
          await widgetTester.pumpAndSettle();

          final texts2 = widgetTester.widgetList<Text>(find.byType(Text));
          expect(
            texts2.elementAt(3).data,
            equals(formatSecondsOfTime(secondsOfHour)),
          );

          expect(
            await PreferenceRepository().shipByKey(notifyAfterInactivity).then(
                  (v) => v.value,
                ),
            equals(secondsOfHour),
          );

          expect(
            initializeCount,
            equals(
              defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
            ),
            reason: 'initializeCount',
          );
          expect(
            registerOneOffTaskCount,
            equals(
              defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
            ),
            reason: 'registerOneOffTask',
          );
        });

        group("With saved", () {
          setUp(() async {
            await PreferenceRepository()
                .receive(PreferenceEntity(notifyAfterInactivity, 3600));

            PreferenceClient.resetSingleton();
          });

          testWidgets("[flaky]Remove.", (widgetTester) async {
            widgetTester.clearAllMockMethodCallHandler();

            int initializeCount = 0;
            int cancelTaskByUniqueNameCount = 0;
            widgetTester.setMockMethodCallHandler(
                MethodChannelMock.workmanagerForeground, [
              (m) async {
                expect(m.method, equals('initialize'));
                initializeCount++;
                return true;
              },
              (m) async {
                expect(m.method, equals('cancelTaskByUniqueName'));
                cancelTaskByUniqueNameCount++;
                return true;
              },
            ]);

            await runApplication();
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(drawerIconFinder);
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.text(l10n.settingsPageTitle));
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.text(l10n.notifyAfterInactivityLabel));
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.text(l10n.cancelAction));
            await widgetTester.pumpAndSettle();

            expect(
              await PreferenceRepository()
                  .shipByKey(notifyAfterInactivity)
                  .then(
                    (v) => v.value,
                  ),
              isNull,
            );

            expect(
              initializeCount,
              equals(
                defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
              ),
              reason: 'initializeCount',
            );
            expect(
              cancelTaskByUniqueNameCount,
              equals(
                defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
              ),
              reason: 'registerOneOffTask',
            );
          });

          group("With habit operation", () {
            setUp(() async {
              ActsClient.resetSingleton();

              final savedMemWithNoAct = await MemRepository().receive(MemEntity(
                  Mem("$_scenarioName - With habit operation - with no act",
                      null, null)));
              await MemNotificationRepository().receive(MemNotificationEntity(
                  MemNotification.by(savedMemWithNoAct.id,
                      MemNotificationType.afterActStarted, 1, "with no act")));
              final savedMemWithActiveAct = await MemRepository().receive(
                  MemEntity(Mem(
                      "$_scenarioName - With habit operation - with active act",
                      null,
                      null)));
              await MemNotificationRepository().receive(MemNotificationEntity(
                  MemNotification.by(
                      savedMemWithActiveAct.id,
                      MemNotificationType.afterActStarted,
                      1,
                      "with active act")));
              await ActRepository().receive(ActEntity(Act.by(
                  savedMemWithActiveAct.id,
                  startWhen: DateAndTime.now())));
            });

            testWidgets("Cancel when start act.", (widgetTester) async {
              widgetTester.clearAllMockMethodCallHandler();
              widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
              widgetTester.ignoreMockMethodCallHandler(
                  MethodChannelMock.permissionHandler);
              widgetTester.ignoreMockMethodCallHandler(
                  MethodChannelMock.flutterLocalNotifications);

              int initializeCount = 0;
              int cancelTaskByUniqueNameCount = 0;
              int registerOneOffTaskCount = 0;
              widgetTester.setMockMethodCallHandler(
                MethodChannelMock.workmanagerForeground,
                [
                  (m) async {
                    expect(m.method, equals('initialize'));
                    initializeCount++;
                    return true;
                  },
                  (m) async {
                    expect(m.method, equals('cancelTaskByUniqueName'));
                    cancelTaskByUniqueNameCount++;
                    return true;
                  },
                  (m) async {
                    expect(m.method, equals('registerOneOffTask'));
                    registerOneOffTaskCount++;
                    return true;
                  },
                  (m) async {
                    expect(m.method, equals('cancelTaskByUniqueName'));
                    cancelTaskByUniqueNameCount++;
                    return true;
                  },
                  (m) async {
                    expect(m.method, equals('cancelTaskByUniqueName'));
                    cancelTaskByUniqueNameCount++;
                    return true;
                  },
                  (m) async {
                    expect(m.method, equals('cancelTaskByUniqueName'));
                    cancelTaskByUniqueNameCount++;
                    return true;
                  },
                  (m) async {
                    expect(m.method, equals('cancelTaskByUniqueName'));
                    cancelTaskByUniqueNameCount++;
                    return true;
                  },
                ],
              );

              await runApplication();
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(startIconFinder.at(0));
              await widgetTester.pumpAndSettle(waitLongSideEffectDuration);

              expect(
                initializeCount,
                equals(
                  defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                ),
                reason: 'initializeCount',
              );
              expect(
                cancelTaskByUniqueNameCount,
                equals(
                  defaultTargetPlatform == TargetPlatform.android ? 5 : 0,
                ),
                reason: 'cancelTaskByUniqueName',
              );
              expect(
                registerOneOffTaskCount,
                equals(
                  defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                ),
                reason: 'registerOneOffTaskCount',
              );
            });

            testWidgets("Set when finish act.", (widgetTester) async {
              widgetTester.clearAllMockMethodCallHandler();
              widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
              widgetTester.ignoreMockMethodCallHandler(
                  MethodChannelMock.permissionHandler);
              widgetTester.ignoreMockMethodCallHandler(
                  MethodChannelMock.flutterLocalNotifications);

              int initializeCount = 0;
              int cancelTaskByUniqueNameCount = 0;
              int registerOneOffTaskCount = 0;
              widgetTester.setMockMethodCallHandler(
                  MethodChannelMock.workmanagerForeground, [
                (m) async {
                  expect(m.method, equals('initialize'));
                  initializeCount++;
                  return true;
                },
                (m) async {
                  expect(m.method, equals('cancelTaskByUniqueName'));
                  cancelTaskByUniqueNameCount++;
                  return true;
                },
                (m) async {
                  expect(m.method, equals('registerOneOffTask'));
                  registerOneOffTaskCount++;
                  return true;
                },
              ]);

              await runApplication();
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(stopIconFinder.at(0));
              await widgetTester.pumpAndSettle(waitLongSideEffectDuration);

              expect(
                initializeCount,
                equals(
                  defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                ),
                reason: 'initializeCount',
              );
              expect(
                cancelTaskByUniqueNameCount,
                equals(
                  defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                ),
                reason: 'cancelTaskByUniqueNameCount',
              );
              expect(
                registerOneOffTaskCount,
                equals(
                  defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                ),
                reason: 'registerOneOffTaskCount',
              );
            });

            testWidgets("Set when pause act.", (widgetTester) async {
              widgetTester.clearAllMockMethodCallHandler();
              widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
              widgetTester.ignoreMockMethodCallHandler(
                  MethodChannelMock.permissionHandler);
              widgetTester.ignoreMockMethodCallHandler(
                  MethodChannelMock.flutterLocalNotifications);

              int initializeCount = 0;
              int cancelTaskByUniqueNameCount = 0;
              int registerOneOffTaskCount = 0;
              widgetTester.setMockMethodCallHandler(
                  MethodChannelMock.workmanagerForeground, [
                (m) async {
                  expect(m.method, equals('initialize'));
                  initializeCount++;
                  return true;
                },
                ...List.filled(4, (m) async {
                  expect(m.method, equals('cancelTaskByUniqueName'));
                  cancelTaskByUniqueNameCount++;
                  return false;
                }),
                (m) async {
                  expect(m.method, equals('registerOneOffTask'));
                  registerOneOffTaskCount++;
                  return true;
                },
              ]);

              await runApplication();
              await widgetTester.pumpAndSettle();
              await widgetTester.tap(pauseIconFinder);
              await widgetTester.pumpAndSettle(waitLongSideEffectDuration);

              expect(
                initializeCount,
                equals(
                  defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                ),
                reason: 'initializeCount',
              );
              expect(
                cancelTaskByUniqueNameCount,
                equals(
                  defaultTargetPlatform == TargetPlatform.android ? 4 : 0,
                ),
                reason: 'cancelTaskByUniqueNameCount',
              );
              expect(
                registerOneOffTaskCount,
                equals(
                  defaultTargetPlatform == TargetPlatform.android ? 1 : 0,
                ),
                reason: 'registerOneOffTaskCount',
              );
            });
          });
        });
      });

      group("Reset Notification", () {
        final insertedMemIds = List<int>.empty(growable: true);

        setUp(() async {
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

        testWidgets('Execute.', (widgetTester) async {
          widgetTester.ignoreMockMethodCallHandler(MethodChannelMock.mem);
          widgetTester
              .ignoreMockMethodCallHandler(MethodChannelMock.permissionHandler);
          widgetTester.ignoreMockMethodCallHandler(
              MethodChannelMock.workmanagerForeground);

          int flutterLocalNotificationsInitializeCount = 0;
          int getNotificationAppLaunchDetailsCount = 0;
          int cancelAllCount = 0;
          int deleteNotificationChannelCount = 0;
          widgetTester.setMockMethodCallHandler(
              MethodChannelMock.flutterLocalNotifications, [
            (m) async {
              expect(m.method, equals('initialize'));
              flutterLocalNotificationsInitializeCount++;
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

          var indicator =
              widgetTester.elementList(find.byType(CircularProgressIndicator));
          while (indicator.length == 1) {
            await widgetTester.pump();
            indicator = widgetTester
                .elementList(find.byType(CircularProgressIndicator));
          }

          expect(find.byType(CircularProgressIndicator), findsNothing);
          expect(find.text(l10n.completeResetNotification), findsOneWidget);

          expect(
            flutterLocalNotificationsInitializeCount,
            equals(defaultTargetPlatform == TargetPlatform.android ? 1 : 0),
            reason: 'flutterLocalNotificationsInitializeCount',
          );
          expect(
            getNotificationAppLaunchDetailsCount,
            equals(defaultTargetPlatform == TargetPlatform.android ? 1 : 0),
            reason: 'getNotificationAppLaunchDetailsCount',
          );
          expect(
            cancelAllCount,
            equals(defaultTargetPlatform == TargetPlatform.android ? 1 : 0),
            reason: 'cancelAllCount',
          );
          expect(
            deleteNotificationChannelCount,
            equals(defaultTargetPlatform == TargetPlatform.android
                ? NotificationType.values.length
                : 0),
            reason: 'deleteNotificationChannelCount',
          );

          widgetTester.clearAllMockMethodCallHandler();
        });
      });
    });
