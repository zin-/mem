import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/settings/constants.dart';
import 'package:mem/features/settings/page.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:settings_ui/settings_ui.dart';

const _name = 'SettingsPage test';

// テスト用の定数
class _TestConstants {
  static const int startOfDayLabelIndex = 0;
  static const int startOfDayValueIndex = 1;
  static const int notifyAfterInactivityLabelIndex = 2;
  static const int notifyAfterInactivityValueIndex = 3;
  static const int resetNotificationLabelIndex = 4;
  static const int appBarTitleIndex = 8;

  static const int startOfDayTileIndex = 0;
  static const int notifyAfterInactivityTileIndex = 1;
}

// ヘルパー関数
Widget _createTestWidget() {
  return ProviderScope(
    overrides: [
      preferenceProvider(startOfDayKey).overrideWith(
        () => _FakePreference(),
      ),
    ],
    child: MaterialApp(home: SettingsPage()),
  );
}

Future<void> _pumpAndSettle(WidgetTester tester) async {
  await tester.pumpWidget(_createTestWidget());
  await tester.pumpAndSettle();
}

Text _getTextWidget(WidgetTester tester, int index) {
  final textWidgets = find.byType(Text);
  return tester.widget<Text>(textWidgets.at(index));
}

SettingsTile _getSettingsTile(WidgetTester tester, int index) {
  final settingsTiles = find.byType(SettingsTile);
  return tester.widget<SettingsTile>(settingsTiles.at(index));
}

void _verifyTextContent(Text textWidget, String expectedContent) {
  expect(textWidget.data, equals(expectedContent));
}

void _verifyTextIsNotEmpty(Text textWidget) {
  expect(textWidget.data, isNotNull);
  expect(textWidget.data, isNotEmpty);
}

void _verifyMultipleTextWidgets(WidgetTester tester, List<int> indices) {
  for (final index in indices) {
    _verifyTextIsNotEmpty(_getTextWidget(tester, index));
  }
}

void _verifySettingsTileValue(SettingsTile tile) {
  expect(tile.value, isA<Text>());
  final valueText = tile.value as Text;
  _verifyTextIsNotEmpty(valueText);
}

void _verifyMultipleSettingsTiles(WidgetTester tester, List<int> indices) {
  for (final index in indices) {
    _verifySettingsTileValue(_getSettingsTile(tester, index));
  }
}

void main() {
  group(_name, () {
    testWidgets(
      'should display basic structure',
      (tester) async {
        final l10n = buildL10n();
        await _pumpAndSettle(tester);

        _verifyTextContent(
          _getTextWidget(tester, _TestConstants.startOfDayLabelIndex),
          l10n.startOfDayLabel,
        );

        _verifyTextContent(
          _getTextWidget(
              tester, _TestConstants.notifyAfterInactivityLabelIndex),
          l10n.notifyAfterInactivityLabel,
        );

        _verifyTextContent(
          _getTextWidget(tester, _TestConstants.resetNotificationLabelIndex),
          l10n.resetNotificationLabel,
        );

        _verifyTextContent(
          _getTextWidget(tester, _TestConstants.appBarTitleIndex),
          l10n.settingsPageTitle,
        );

        _verifyMultipleTextWidgets(tester, [
          _TestConstants.startOfDayValueIndex,
          _TestConstants.notifyAfterInactivityValueIndex,
        ]);
      },
    );

    testWidgets(
      'should display correct values in SettingsTile',
      (tester) async {
        await _pumpAndSettle(tester);

        _verifyMultipleSettingsTiles(tester, [
          _TestConstants.startOfDayTileIndex,
          _TestConstants.notifyAfterInactivityTileIndex,
        ]);
      },
    );
  });
}

class _FakePreference<T> extends Preference<T> {
  @override
  T build(PreferenceKey<T> key) => defaultPreferences[key] as T;
}
