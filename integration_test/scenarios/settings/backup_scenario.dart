import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/repository/database_repository.dart';
import 'package:mem/logger/log.dart';
import 'package:mem/logger/log_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

import '../helpers.dart';

const _scenarioName = 'Backup scenario';

void main() => group(
      _scenarioName,
      () {
        const numberOfMem = 100;
        const baseInsertedMemName = '$_scenarioName - mem name - inserted';

        LogService(
          level: Level.verbose,
          enableSimpleLog:
              const bool.fromEnvironment('CICD', defaultValue: false),
        );

        late final DatabaseAccessor dbA;
        final insertedMemIds = List<int>.empty(growable: true);
        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);

          await clearAllTestDatabaseRows(databaseDefinition);

          for (var i = 0; i < numberOfMem; i++) {
            insertedMemIds.add(
              await dbA.insert(
                defTableMems,
                {
                  defColMemsName.name: "$baseInsertedMemName: $i",
                  defColCreatedAt.name: zeroDate,
                },
              ),
            );
          }
        });

        testWidgets(
          "create.",
          retry: maxRetryCount,
          (widgetTester) async {
            String? result;
            switch (defaultTargetPlatform) {
              case TargetPlatform.android:
                widgetTester.ignoreMockMethodCallHandler(
                    MethodChannelMock.flutterLocalNotifications);
                widgetTester
                    .setMockMethodCallHandler(MethodChannelMock.sharePlus, [
                  (message) async {
                    await Future.delayed(const Duration(milliseconds: 500));
                    expect(message.method, equals("shareFilesWithResult"));
                    return result = "Success.";
                  }
                ]);
                break;

              case TargetPlatform.windows:
                final downloadsDirectory = await getDownloadsDirectory();
                result = path.join(downloadsDirectory!.path, "test_mem.db");
                break;

              default:
                throw UnimplementedError();
            }

            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(drawerIconFinder);
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.text(l10n.settingsPageTitle));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.text(l10n.createBackupLabel));
            await widgetTester.pump();

            // expect(find.byType(CircularProgressIndicator), findsOneWidget);

            await widgetTester
                .pumpAndSettle(const Duration(milliseconds: 1500));

            expect(find.byType(CircularProgressIndicator), findsNothing);
            expect(find.text(result!), findsOneWidget);
          },
        );

        if (defaultTargetPlatform != TargetPlatform.windows) {
          group(
            'restore',
            () {
              testWidgets(
                'pick nothing.',
                (widgetTester) async {
                  widgetTester.ignoreMockMethodCallHandler(
                      MethodChannelMock.flutterLocalNotifications);
                  widgetTester.setMockMethodCallHandler(
                    MethodChannelMock.filePicker,
                    [
                      (m) async {
                        expect(m.method, 'any');
                        return null;
                      }
                    ],
                  );

                  await runApplication();
                  await widgetTester.pumpAndSettle();

                  await widgetTester.tap(drawerIconFinder);
                  await widgetTester.pumpAndSettle();
                  await widgetTester.tap(find.text(l10n.settingsPageTitle));
                  await widgetTester.pumpAndSettle();

                  await widgetTester.tap(find.text(l10n.restoreBackupLabel));
                  await widgetTester.pump();

                  expect(find.text(l10n.canceledRestoreBackup), findsOneWidget);
                },
              );

              testWidgets(
                'pick backup file.',
                (widgetTester) async {
                  final current = (await DatabaseRepository()
                      .shipFileByNameIs(databaseDefinition.name))!;
                  const backupFileName = 'backup';
                  final backupFilePath = current.path.replaceFirst(
                      path.basename(current.path), backupFileName);
                  current.copy(backupFilePath);

                  widgetTester.ignoreMockMethodCallHandler(
                      MethodChannelMock.flutterLocalNotifications);
                  widgetTester.setMockMethodCallHandler(
                    MethodChannelMock.filePicker,
                    [
                      (m) async {
                        expect(m.method, 'any');
                        return [
                          {
                            'name': backupFileName,
                            'path': backupFilePath,
                            'size': 1,
                          },
                        ];
                      }
                    ],
                  );

                  await runApplication();
                  await widgetTester.pumpAndSettle();

                  await widgetTester.tap(drawerIconFinder);
                  await widgetTester.pumpAndSettle();
                  await widgetTester.tap(find.text(l10n.settingsPageTitle));
                  await widgetTester.pumpAndSettle();

                  await widgetTester.tap(find.text(l10n.restoreBackupLabel));
                  await widgetTester.pumpAndSettle();

                  expect(find.text(l10n.completedRestoreBackup(backupFileName)),
                      findsOneWidget);
                },
              );
            },
          );
        }
      },
    );
