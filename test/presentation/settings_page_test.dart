import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/settings/constants.dart';
import 'package:mem/features/settings/page.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/l10n/l10n.dart';

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

        expect(find.text(l10n.settingsPageTitle), findsOneWidget);
        expect(find.text(l10n.startOfDayLabel), findsOneWidget);
        expect(find.text(l10n.notifyAfterInactivityLabel), findsOneWidget);
        expect(find.text(l10n.resetNotificationLabel), findsOneWidget);
      },
    );
  });
}

class _FakePreference<T> extends Preference<T> {
  @override
  T build(PreferenceKey<T> key) => defaultPreferences[key] as T;
}
