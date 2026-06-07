import 'package:flutter/material.dart';
import '../../../entity_factories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_time_ext.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';

class _FakeMemEntities extends MemEntities {
  final Iterable<SavedMemEntityV1> _state;

  _FakeMemEntities(this._state);

  @override
  Iterable<SavedMemEntityV1> build() => _state;
}

class _FakePreference extends Preference<TimeOfDay> {
  _FakePreference();

  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 9, minute: 0);
}

ProviderContainer _memListContainer(
  Iterable<SavedMemEntityV1> mems, {
  Iterable<SavedMemNotificationEntityV1> notifications = const [],
}) {
  return ProviderContainer(
    overrides: [
      preferenceProvider(startOfDayKey).overrideWith(() => _FakePreference()),
      memEntitiesProvider.overrideWith(() => _FakeMemEntities(mems)),
      memNotificationsProvider.overrideWith(
        (ref) => ListValueStateNotifier<MemNotificationEntityV1>(
          notifications.toList(),
        ),
      ),
      savedMemNotificationsProvider.overrideWith(
        (ref) => ListValueStateNotifier<SavedMemNotificationEntityV1>(
          notifications.toList(),
        ),
      ),
    ],
  );
}

void main() {
  group('memListProvider', () {
    test('sorts PausedAct mems by pausedAt descending', () {
      final olderPaused = savedMem(
        id: 1,
        name: 'Older pause',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        latestAct: PausedAct(1, DateTime(2024, 6, 1, 10, 0)),
      );
      final newerPaused = savedMem(
        id: 2,
        name: 'Newer pause',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        latestAct: PausedAct(2, DateTime(2024, 6, 1, 12, 0)),
      );

      final container = _memListContainer([olderPaused, newerPaused]);
      addTearDown(container.dispose);

      final sortedIds =
          container.read(memListProvider).map((mem) => mem.id).toList();

      expect(sortedIds, [2, 1]);
    });

    test('keeps ActiveAct mem above PausedAct mem', () {
      final active = savedMem(
        id: 1,
        name: 'Active',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        latestAct: ActiveAct(1, DateAndTime(2024, 6, 1, 8, 0)),
      );
      final paused = savedMem(
        id: 2,
        name: 'Paused',
        createdAt: DateTime(2024, 6, 1),
        updatedAt: DateTime(2024, 6, 1),
        latestAct: PausedAct(2, DateTime(2024, 6, 1, 12, 0)),
      );

      final container = _memListContainer([paused, active]);
      addTearDown(container.dispose);

      final sortedIds =
          container.read(memListProvider).map((mem) => mem.id).toList();

      expect(sortedIds, [1, 2]);
    });
  });

  group('memList section date', () {
    final startOfToday = DateTime(2024, 10, 12, 9, 0);
    final skipDay = DateAndTime(2024, 10, 12, 12, 0);

    Act skippedOnToday(int memId) => Act.by(
          memId,
          startWhen: skipDay,
          endWhen: skipDay,
          completionKind: ActKind.skipped,
        );

    MemEntity memWithSkipped({
      required int id,
      Act? scheduleAnchorAct,
    }) =>
        savedMem(
          id: id,
          name: 'Skipped today',
          createdAt: DateTime(2024, 10, 1),
          updatedAt: DateTime(2024, 10, 12),
          latestAct: skippedOnToday(id),
        ).toEntityV2().updatedWith(
              scheduleAnchorAct: () => scheduleAnchorAct,
            );

    test(
        'skipped on today with weekly anchor is not grouped under skip day section',
        () {
      final anchor = Act.by(
        1,
        startWhen: DateAndTime(2024, 10, 5, 12, 0),
        endWhen: DateAndTime(2024, 10, 5, 12, 0),
        completionKind: ActKind.finished,
      );
      final notifications = [
        MemNotification.by(
          0,
          MemNotificationType.repeatByNDay,
          7,
          'repeat by 7 day',
        ),
      ];

      final sectionDate = memWithSkipped(id: 1, scheduleAnchorAct: anchor)
          .toDomain()
          .memListSectionDate(startOfToday, notifications);

      expect(sectionDate, isNot(DateAndTime(2024, 10, 12)));
      expect(sectionDate, DateAndTime(2024, 10, 19));
    });

    test('skip alone on today is not grouped under skip day section', () {
      final notifications = [
        MemNotification.by(
          0,
          MemNotificationType.repeatByNDay,
          2,
          'repeat by 2 day',
        ),
      ];

      final sectionDate = memWithSkipped(id: 1)
          .toDomain()
          .memListSectionDate(startOfToday, notifications);

      expect(sectionDate, isNot(DateAndTime(2024, 10, 12)));
      expect(sectionDate, DateAndTime(2024, 10, 14));
    });
  });

  group('startOfToday', () {
    const startOfDay = TimeOfDay(hour: 9, minute: 0);
    final now = DateTime(2024, 10, 12, 3, 0);

    Iterable<MemNotification> repeatAtHourNotifications(int memId, int hour) =>
        [
          MemNotification.by(
            memId,
            MemNotificationType.repeat,
            hour * 60 * 60,
            'repeat at $hour:00',
          ),
        ];

    test('before start of day returns previous calendar day at startOfDay', () {
      expect(
        DateTimeExt.startOfToday(startOfDay, now),
        DateTime(2024, 10, 11, 9, 0),
      );
    });

    test('repeat at 8:00 section date uses same startOfToday as sort', () {
      final sortStartOfToday = DateTimeExt.startOfToday(startOfDay, now);
      final mem = Mem(1, 'Daily repeat', null, null);
      final notifications = repeatAtHourNotifications(1, 8);

      expect(
        mem.memListSectionDate(sortStartOfToday, notifications),
        DateAndTime(2024, 10, 11),
      );
    });

    test('memListProvider notifyAt order uses same startOfToday as section date',
        () {
      final sortStartOfToday = DateTimeExt.startOfToday(startOfDay, now);
      final mem = savedMem(
        id: 1,
        name: 'Daily repeat',
        createdAt: DateTime(2024, 10, 1),
        updatedAt: DateTime(2024, 10, 1),
      );
      final notification = savedMemNotification(
        id: 1,
        memId: 1,
        type: MemNotificationType.repeat,
        timeOfDaySeconds: 8 * 60 * 60,
        message: 'repeat at 8:00',
        createdAt: DateTime(2024, 10, 1),
        updatedAt: DateTime(2024, 10, 1),
      );

      final container = _memListContainer([mem], notifications: [notification]);
      addTearDown(container.dispose);

      final sortedMem = container.read(memListProvider).single.toDomain();
      final notificationsForMem = [notification.value];

      expect(
        sortedMem.memListSectionDate(sortStartOfToday, notificationsForMem),
        DateAndTime(2024, 10, 11),
      );
      expect(
        sortedMem.notifyAt(sortStartOfToday, notificationsForMem, null),
        DateTime(2024, 10, 12, 8, 0),
      );
    });
  });
}
