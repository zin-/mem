import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:settings_ui/settings_ui.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testSettingsScenario();
}

const _scenarioName = "Settings test";

void testSettingsScenario() => group(
      ": $_scenarioName",
      () {
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
            expect(find.text(l10n.start_of_day_label), findsOneWidget);
          },
        );

        testWidgets(
          ": pick & remove start of day.",
          (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            await _openDrawer(widgetTester);
            await _showPage(widgetTester);

            final now = DateTime.now();
            await widgetTester.tap(find.text(l10n.start_of_day_label));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(okFinder);
            await widgetTester.pumpAndSettle();

            expect(
              find.descendant(
                of: find.byType(SettingsTile),
                matching: find.text(timeText(now)),
              ),
              findsOneWidget,
            );

            await widgetTester.tap(find.text(l10n.start_of_day_label));
            await widgetTester.pumpAndSettle();
            await widgetTester.tap(cancelFinder);
            await widgetTester.pumpAndSettle();

            expect(find.text(timeText(now)), findsNothing);
          },
        );

        testWidgets(
          ": show saved.",
          (widgetTester) async {
            await runApplication();
            await widgetTester.pumpAndSettle();

            await _openDrawer(widgetTester);
            await _showPage(widgetTester);

            final now = DateTime.now();
            await widgetTester.tap(find.text(l10n.start_of_day_label));
            await widgetTester.pumpAndSettle();

            await widgetTester.tap(okFinder);
            await widgetTester.pumpAndSettle();

            await widgetTester.pageBack();
            await widgetTester.pumpAndSettle();

            await _showPage(widgetTester);

            expect(
              find.descendant(
                of: find.byType(SettingsTile),
                matching: find.text(timeText(now)),
              ),
              findsOneWidget,
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
