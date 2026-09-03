import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_notifications_text.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mem/l10n/l10n.dart';

import '../../entity_factories.dart';

class _FakePreference extends Preference<TimeOfDay> {
  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 0, minute: 0);
}

SavedMemNotificationEntityV1 _notification({
  required int id,
  required MemNotificationType type,
  required int time,
}) {
  final now = DateTime.now();
  return savedMemNotification(
    id: id,
    memId: 1,
    type: type,
    timeOfDaySeconds: time,
    message: type.name,
    createdAt: now,
    updatedAt: now,
  );
}

Future<void> _pumpText(
  WidgetTester tester, {
  required List<MemNotificationEntityV1> notifications,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        memNotificationsByMemIdProvider(1).overrideWith(
          (ref) => ListValueStateNotifier(notifications),
        ),
        preferenceProvider(startOfDayKey).overrideWith(
          () => _FakePreference(),
        ),
        memEntitiesProvider.overrideWithValue([]),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        onGenerateTitle: (context) => buildL10n(context).test,
        home: const Scaffold(
          body: MemNotificationText(1),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('MemNotificationText', () {
    testWidgets('formats weekdays and after-act time from localizations',
        (tester) async {
      await _pumpText(
        tester,
        notifications: [
          _notification(
            id: 1,
            type: MemNotificationType.repeatByDayOfWeek,
            time: DateTime.monday,
          ),
          _notification(
            id: 2,
            type: MemNotificationType.repeatByDayOfWeek,
            time: DateTime.sunday,
          ),
          _notification(
            id: 3,
            type: MemNotificationType.afterActStarted,
            time: 60 * 60,
          ),
        ],
      );

      final context = tester.element(find.byType(MemNotificationText));
      final formattedTime =
          const TimeOfDay(hour: 1, minute: 0).format(context);
      final l10n = buildL10n(context);

      expect(
        find.text(
          'Sun, Mon, ${l10n.afterActStartedNotificationText(formattedTime)}',
        ),
        findsOneWidget,
      );
    });
  });
}
