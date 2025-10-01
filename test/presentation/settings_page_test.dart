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

void _verifyMultipleTextWidgets(WidgetTester tester, List<int> indices) {
  for (final index in indices) {
    final textWidget = tester.widget<Text>(find.byType(Text).at(index));
    expect(textWidget.data, isNotNull);
    expect(textWidget.data, isNotEmpty);
  }
}

void _verifyMultipleSettingsTiles(WidgetTester tester, List<int> indices) {
  for (final index in indices) {
    final tile =
        tester.widget<SettingsTile>(find.byType(SettingsTile).at(index));
    expect(tile.value, isA<Text>());
    final valueText = tile.value as Text;
    expect(valueText.data, isNotNull);
    expect(valueText.data, isNotEmpty);
  }
}

void main() {
  group(_name, () {
    testWidgets(
      'should display basic structure',
      (tester) async {
        final l10n = buildL10n();
        await _pumpAndSettle(tester);

        final textWidgets = find.byType(Text);

        expect(
          tester
              .widget<Text>(textWidgets.at(_TestConstants.startOfDayLabelIndex))
              .data,
          equals(l10n.startOfDayLabel),
        );

        expect(
          tester
              .widget<Text>(textWidgets
                  .at(_TestConstants.notifyAfterInactivityLabelIndex))
              .data,
          equals(l10n.notifyAfterInactivityLabel),
        );

        expect(
          tester
              .widget<Text>(
                  textWidgets.at(_TestConstants.resetNotificationLabelIndex))
              .data,
          equals(l10n.resetNotificationLabel),
        );

        expect(
          tester
              .widget<Text>(textWidgets.at(_TestConstants.appBarTitleIndex))
              .data,
          equals(l10n.settingsPageTitle),
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
