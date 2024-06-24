import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
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

        LogService.initialize(
          Level.warning,
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
          retry: 3,
          (widgetTester) async {
            String? result;
            switch (defaultTargetPlatform) {
              case TargetPlatform.android:
                widgetTester.binding.defaultBinaryMessenger
                    .setMockMethodCallHandler(
                  const MethodChannel("dev.fluttercommunity.plus/share"),
                  (message) async {
                    await Future.delayed(const Duration(milliseconds: 500));
                    expect(message.method, equals("shareFilesWithResult"));
                    return result = "Success.";
                  },
                );
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

            expect(find.byType(CircularProgressIndicator), findsOneWidget);

            await widgetTester
                .pumpAndSettle(const Duration(milliseconds: 1500));

            expect(find.byType(CircularProgressIndicator), findsNothing);
            expect(find.text(result!), findsOneWidget);
          },
        );

        testWidgets(
          'restore.',
          (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(drawerIconFinder);
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(find.text(l10n.settingsPageTitle));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(find.text(l10n.restoreBackupLabel));
            await widgetTester.pump();
          },
        );
      },
    );
