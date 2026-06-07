import 'package:flutter/material.dart';
import '../../../entity_factories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';

DateAndTime? memListSectionDate({
  required MemEntity mem,
  required DateTime startOfToday,
  required Iterable<MemNotification> notifications,
}) {
  final nextNotifyAt = mem.toDomain().notifyAt(
    startOfToday,
    notifications,
    mem.latestAct,
  );
  if (nextNotifyAt == null) return null;
  if (notifications.where((e) => !e.isAfterActStarted()).isNotEmpty &&
      TimeOfDay.fromDateTime(nextNotifyAt)
          .isBefore(TimeOfDay.fromDateTime(startOfToday))) {
    return DateAndTime(
      nextNotifyAt.year,
      nextNotifyAt.month,
      nextNotifyAt.day,
    ).subtract(const Duration(days: 1));
  }
  return DateAndTime(
    nextNotifyAt.year,
    nextNotifyAt.month,
    nextNotifyAt.day,
  );
}

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

ProviderContainer _memListContainer(Iterable<SavedMemEntityV1> mems) {
  return ProviderContainer(
    overrides: [
      preferenceProvider(startOfDayKey).overrideWith(() => _FakePreference()),
      memEntitiesProvider.overrideWith(() => _FakeMemEntities(mems)),
      memNotificationsProvider.overrideWith(
        (ref) => ListValueStateNotifier<MemNotificationEntityV1>([]),
      ),
      savedMemNotificationsProvider.overrideWith(
        (ref) => ListValueStateNotifier<SavedMemNotificationEntityV1>([]),
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

      final sectionDate = memListSectionDate(
        mem: memWithSkipped(id: 1, scheduleAnchorAct: anchor),
        startOfToday: startOfToday,
        notifications: notifications,
      );

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

      final sectionDate = memListSectionDate(
        mem: memWithSkipped(id: 1),
        startOfToday: startOfToday,
        notifications: notifications,
      );

      expect(sectionDate, isNot(DateAndTime(2024, 10, 12)));
      expect(sectionDate, DateAndTime(2024, 10, 14));
    });
  });
}
