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

void main() {
  group(_name, () {
    testWidgets(
      'should display basic structure',
      (tester) async {
        final l10n = buildL10n();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferenceProvider(startOfDayKey).overrideWith(
                () => _FakePreference(),
              ),
            ],
            child: MaterialApp(home: SettingsPage()),
          ),
        );

        await tester.pumpAndSettle();

        // Textウィジェットの順番で内容を検証
        final textWidgets = find.byType(Text);
        // 0番目: 開始時刻のラベル
        final startOfDayText = tester.widget<Text>(textWidgets.at(0));
        expect(startOfDayText.data, equals(l10n.startOfDayLabel));

        // 1番目: 開始時刻の値（時間表示）
        final startOfDayValueText = tester.widget<Text>(textWidgets.at(1));
        expect(startOfDayValueText.data, isNotNull);
        expect(startOfDayValueText.data, isNotEmpty);

        // 2番目: 非アクティブ通知のラベル
        final notifyAfterInactivityText =
            tester.widget<Text>(textWidgets.at(2));
        expect(notifyAfterInactivityText.data,
            equals(l10n.notifyAfterInactivityLabel));

        // 3番目: 非アクティブ通知の値
        final notifyAfterInactivityValueText =
            tester.widget<Text>(textWidgets.at(3));
        expect(notifyAfterInactivityValueText.data, isNotNull);
        expect(notifyAfterInactivityValueText.data, isNotEmpty);

        // 4番目: リセット通知のラベル
        final resetNotificationText = tester.widget<Text>(textWidgets.at(4));
        expect(resetNotificationText.data, equals(l10n.resetNotificationLabel));

        // 8番目: AppBarのタイトル（最後）
        final titleText = tester.widget<Text>(textWidgets.at(8));
        expect(titleText.data, equals(l10n.settingsPageTitle));
      },
    );

    testWidgets(
      'should display correct values in SettingsTile',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              preferenceProvider(startOfDayKey).overrideWith(
                () => _FakePreference(),
              ),
            ],
            child: MaterialApp(home: SettingsPage()),
          ),
        );

        await tester.pumpAndSettle();

        // SettingsTileの順番でvalueプロパティの内容を検証
        final settingsTiles = find.byType(SettingsTile);

        // 1番目のSettingsTile（開始時刻）のvalueプロパティを検証
        final startOfDayTile = tester.widget<SettingsTile>(settingsTiles.at(0));
        expect(startOfDayTile.value, isA<Text>());

        // 実際の時間表示を検証
        final startOfDayValueText = startOfDayTile.value as Text;
        expect(startOfDayValueText.data, isNotNull);
        expect(startOfDayValueText.data, isNotEmpty);

        // 2番目のSettingsTile（非アクティブ通知）のvalueプロパティを検証
        final notifyAfterInactivityTile =
            tester.widget<SettingsTile>(settingsTiles.at(1));
        expect(notifyAfterInactivityTile.value, isA<Text>());

        // 実際の通知設定表示を検証
        final notifyAfterInactivityValueText =
            notifyAfterInactivityTile.value as Text;
        expect(notifyAfterInactivityValueText.data, isNotNull);
        expect(notifyAfterInactivityValueText.data, isNotEmpty);
      },
    );
  });
}

class _FakePreference<T> extends Preference<T> {
  @override
  T build(PreferenceKey<T> key) => defaultPreferences[key] as T;
}
