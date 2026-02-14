import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_repeated_notification_view.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/date_and_time/time_of_day_view.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';

class _FakePreference extends Preference<TimeOfDay> {
  _FakePreference();

  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 9, minute: 0);
}

Widget _buildTestApp(Widget child, {List<Override>? overrides}) {
  return ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp(
      home: Scaffold(
        body: child,
      ),
    ),
  );
}

void main() {
  group('MemRepeatedNotificationView', () {
    testWidgets('displays TimeOfDayTextFormField with time when time is set',
        (tester) async {
      const memId = 1;
      final now = DateTime.now();
      final notification = SavedMemNotificationEntityV1({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeat',
        defColMemNotificationsTime.name: 9 * 60 * 60 + 30 * 60,
        defColMemNotificationsMessage.name: 'Repeat',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      await tester.pumpWidget(
        _buildTestApp(
          const MemRepeatedNotificationView(1),
          overrides: [
            memNotificationsByMemIdProvider(1).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntityV1>(
                    [notification])),
            preferenceProvider(startOfDayKey).overrideWith(
              () => _FakePreference(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(keyMemRepeatedNotification), findsOneWidget);
      expect(find.byType(TimeOfDayTextFormField), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsOneWidget);
    });

    testWidgets(
        'displays TimeOfDayTextFormField with defaultTime when time is null',
        (tester) async {
      const memId = 1;
      final now = DateTime.now();
      final notification = SavedMemNotificationEntityV1({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeat',
        defColMemNotificationsTime.name: null,
        defColMemNotificationsMessage.name: 'Repeat',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      await tester.pumpWidget(
        _buildTestApp(
          const MemRepeatedNotificationView(1),
          overrides: [
            memNotificationsByMemIdProvider(1).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntityV1>(
                    [notification])),
            preferenceProvider(startOfDayKey).overrideWith(
              () => _FakePreference(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(keyMemRepeatedNotification), findsOneWidget);
      expect(find.byType(TimeOfDayTextFormField), findsOneWidget);
      expect(find.byIcon(Icons.clear), findsNothing);
    });

    testWidgets('calls onTimeChanged when time is changed', (tester) async {
      const memId = 1;
      final now = DateTime.now();
      final notification = SavedMemNotificationEntityV1({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeat',
        defColMemNotificationsTime.name: 9 * 60 * 60 + 30 * 60,
        defColMemNotificationsMessage.name: 'Repeat',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final notifier =
          ListValueStateNotifier<MemNotificationEntityV1>([notification]);

      await tester.pumpWidget(
        _buildTestApp(
          const MemRepeatedNotificationView(1),
          overrides: [
            memNotificationsByMemIdProvider(1).overrideWith((ref) => notifier),
            preferenceProvider(startOfDayKey).overrideWith(
              () => _FakePreference(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final timeOfDayField = tester.widget<TimeOfDayTextFormField>(
        find.byType(TimeOfDayTextFormField),
      );

      timeOfDayField.onChanged(const TimeOfDay(hour: 10, minute: 30));
      await tester.pump();

      final updatedNotification = notifier.state.first;
      expect(updatedNotification.value.time, 10 * 60 * 60 + 30 * 60);
    });

    testWidgets('calls onTimeChanged with null when clear button is pressed',
        (tester) async {
      const memId = 1;
      final now = DateTime.now();
      final notification = SavedMemNotificationEntityV1({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeat',
        defColMemNotificationsTime.name: 9 * 60 * 60 + 30 * 60,
        defColMemNotificationsMessage.name: 'Repeat',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final notifier =
          ListValueStateNotifier<MemNotificationEntityV1>([notification]);

      await tester.pumpWidget(
        _buildTestApp(
          const MemRepeatedNotificationView(1),
          overrides: [
            memNotificationsByMemIdProvider(1).overrideWith((ref) => notifier),
            preferenceProvider(startOfDayKey).overrideWith(
              () => _FakePreference(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.clear));
      await tester.pump();

      final updatedNotification = notifier.state.first;
      expect(updatedNotification.value.time, null);
    });

    testWidgets(
        'calls onTimeChanged with null when TimeOfDayTextFormField returns null',
        (tester) async {
      const memId = 1;
      final now = DateTime.now();
      final notification = SavedMemNotificationEntityV1({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: memId,
        defColMemNotificationsType.name: 'repeat',
        defColMemNotificationsTime.name: 9 * 60 * 60 + 30 * 60,
        defColMemNotificationsMessage.name: 'Repeat',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      final notifier =
          ListValueStateNotifier<MemNotificationEntityV1>([notification]);

      await tester.pumpWidget(
        _buildTestApp(
          const MemRepeatedNotificationView(1),
          overrides: [
            memNotificationsByMemIdProvider(1).overrideWith((ref) => notifier),
            preferenceProvider(startOfDayKey).overrideWith(
              () => _FakePreference(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      final timeOfDayField = tester.widget<TimeOfDayTextFormField>(
        find.byType(TimeOfDayTextFormField),
      );

      timeOfDayField.onChanged(null);
      await tester.pump();

      final updatedNotification = notifier.state.first;
      expect(updatedNotification.value.time, null);
    });

    testWidgets('handles memId null', (tester) async {
      final now = DateTime.now();
      final notification = SavedMemNotificationEntityV1({
        defPkId.name: 1,
        defFkMemNotificationsMemId.name: null,
        defColMemNotificationsType.name: 'repeat',
        defColMemNotificationsTime.name: 9 * 60 * 60 + 30 * 60,
        defColMemNotificationsMessage.name: 'Repeat',
        defColCreatedAt.name: now,
        defColUpdatedAt.name: now,
        defColArchivedAt.name: null,
      });

      await tester.pumpWidget(
        _buildTestApp(
          const MemRepeatedNotificationView(null),
          overrides: [
            memNotificationsByMemIdProvider(null).overrideWith((ref) =>
                ListValueStateNotifier<MemNotificationEntityV1>(
                    [notification])),
            preferenceProvider(startOfDayKey).overrideWith(
              () => _FakePreference(),
            ),
          ],
        ),
      );

      await tester.pumpAndSettle();

      expect(find.byKey(keyMemRepeatedNotification), findsOneWidget);
      expect(find.byType(TimeOfDayTextFormField), findsOneWidget);
    });
  });
}
