import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/settings/client.dart';
import 'package:mem/settings/preference.dart';
import 'package:mem/settings/keys.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:settings_ui/settings_ui.dart';

import 'helpers.dart';

const _scenarioName = "Settings test";

void main() => group(
      ": $_scenarioName",
      () {
        setUpAll(() async {
          await openTestDatabase(databaseDefinition);
        });

        testWidgets(
          ": show page.",
          (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            expect(find.byType(AppBar), findsOneWidget);

            await _openDrawer(widgetTester);

            expect(find.byIcon(Icons.settings), findsOneWidget);
            await widgetTester.tap(find.text(l10n.settingsPageTitle));
            await widgetTester.pumpAndSettle();

            expect(find.text(l10n.settingsPageTitle), findsOneWidget);
            expect(find.byIcon(Icons.start), findsOneWidget);
            expect(find.text(l10n.startOfDayLabel), findsOneWidget);
            expect(find.byIcon(Icons.backup), findsOneWidget);
            expect(find.text(l10n.backupLabel), findsOneWidget);
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

                await _openDrawer(widgetTester);
                await _showPage(widgetTester);

                final now = DateTime.now();
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
                  timeText(now),
                );
                expect(
                  (await PreferenceClient().shipByKey(startOfDayKey)).value,
                  TimeOfDay.fromDateTime(now),
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

                    await _openDrawer(widgetTester);
                    await _showPage(widgetTester);

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

                testWidgets(
                  "remove.",
                  (widgetTester) async {
                    await runApplication();
                    await widgetTester.pumpAndSettle();

                    await _openDrawer(widgetTester);
                    await _showPage(widgetTester);

                    await widgetTester.tap(find.text(l10n.startOfDayLabel));
                    await widgetTester.pumpAndSettle();

                    await widgetTester.tap(cancelFinder);
                    await widgetTester.pumpAndSettle();

                    expect(find.text(timeText(now)), findsNothing);
                    expect(
                      (await PreferenceClient().shipByKey(startOfDayKey)).value,
                      null,
                    );
                  },
                );
              },
            );
          },
        );

        group(
          "Backup",
          () {
            testWidgets(
              "create.",
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

                await _openDrawer(widgetTester);
                await _showPage(widgetTester);

                await widgetTester.tap(find.text(l10n.backupLabel));
                await widgetTester.pump();

                // expect(find.byType(CircularProgressIndicator), findsOneWidget);

                await widgetTester
                    .pumpAndSettle(const Duration(milliseconds: 1500));

                expect(find.byType(CircularProgressIndicator), findsNothing);
                expect(find.text(result!), findsOneWidget);
              },
            );
          },
        );
      },
    );

Future<void> _openDrawer(WidgetTester widgetTester) async {
  await widgetTester.tap(
    find.descendant(
      of: find.descendant(
        of: find.byType(AppBar),
        matching: find.byType(IconButton),
      ),
      matching: find.byType(DrawerButtonIcon),
    ),
  );
  await widgetTester.pumpAndSettle();
}

Future<void> _showPage(WidgetTester widgetTester) async {
  await widgetTester.tap(find.text(l10n.settingsPageTitle));
  await widgetTester.pumpAndSettle();
}
