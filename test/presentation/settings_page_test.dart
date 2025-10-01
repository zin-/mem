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

class _TestConstants {
  static const int startOfDayLabelIndex = 0;
  static const int startOfDayValueIndex = 1;
  static const int notifyAfterInactivityLabelIndex = 2;
  static const int notifyAfterInactivityValueIndex = 3;
  static const int resetNotificationLabelIndex = 4;
  static const int appBarTitleIndex = 8;
}

Widget _createTestWidget() {
  return ProviderScope(
    overrides: [
      preferenceProvider(startOfDayKey).overrideWith(
        () => _FakePreference(),
      ),
      preferenceProvider(notifyAfterInactivity).overrideWith(
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

void main() {
  group(_name, () {
    group('should display', () {
      testWidgets(
        'basic structure.',
        (tester) async {
          final l10n = buildL10n();
          await _pumpAndSettle(tester);

          final textWidgets = find.byType(Text);

          expect(
            tester
                .widget<Text>(
                    textWidgets.at(_TestConstants.startOfDayLabelIndex))
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
        'correct values.',
        (tester) async {
          await _pumpAndSettle(tester);

          final textWidgets = find.byType(Text);

          final startOfDayValue = tester
              .widget<Text>(textWidgets.at(_TestConstants.startOfDayValueIndex))
              .data;
          expect(startOfDayValue, equals('12:00 AM'));

          final notifyAfterInactivityValue = tester
              .widget<Text>(textWidgets
                  .at(_TestConstants.notifyAfterInactivityValueIndex))
              .data;
          expect(notifyAfterInactivityValue, equals('1 h 0 m'));
        },
      );
    });

    group('should change', () {
      testWidgets(
        'start of day value.',
        (tester) async {
          await _pumpAndSettle(tester);

          final textWidgets = find.byType(Text);
          final startOfDayValue = tester
              .widget<Text>(textWidgets.at(_TestConstants.startOfDayValueIndex))
              .data;
          expect(startOfDayValue, equals('12:00 AM'));

          await tester.tap(find.byType(SettingsTile).first);
          await tester.pumpAndSettle();

          expect(find.byType(TimePickerDialog), findsOneWidget);

          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();

          expect(find.byType(TimePickerDialog), findsNothing);
        },
      );

      testWidgets(
        'notify after inactivity value.',
        (tester) async {
          await _pumpAndSettle(tester);

          final textWidgets = find.byType(Text);
          final notifyAfterInactivityValue = tester
              .widget<Text>(textWidgets
                  .at(_TestConstants.notifyAfterInactivityValueIndex))
              .data;
          expect(notifyAfterInactivityValue, equals('1 h 0 m'));

          await tester.tap(find.byType(SettingsTile).at(1));
          await tester.pumpAndSettle();

          expect(find.byType(BottomSheet), findsOneWidget);

          await tester.tap(find.text('OK'));
          await tester.pumpAndSettle();

          expect(find.byType(BottomSheet), findsNothing);
        },
      );
    });
  });
}

class _FakePreference<T> extends Preference<T> {
  T? _value;

  @override
  T build(PreferenceKey<T> key) {
    _value ??= defaultPreferences[key] as T;
    return _value as T;
  }

  @override
  Future<void> replace(T updating) async {
    _value = updating;
    state = updating;
  }

  @override
  Future<void> remove() async {
    _value = defaultPreferences[key] as T;
    state = _value as T;
  }
}
