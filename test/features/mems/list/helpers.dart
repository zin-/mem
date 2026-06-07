import '../../../entity_factories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';

class FakeStartOfDayPreference extends Preference<TimeOfDay> {
  FakeStartOfDayPreference([
    this.startOfDay = const TimeOfDay(hour: 9, minute: 0),
  ]);

  final TimeOfDay startOfDay;

  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) => startOfDay;
}

class FakeMemEntities extends MemEntities {
  FakeMemEntities([this._initialState = const []]);

  final Iterable<SavedMemEntityV1> _initialState;

  @override
  Iterable<SavedMemEntityV1> build() => _initialState;
}

SavedMemNotificationEntityV1 savedRepeatAtHourNotification({
  required int id,
  required int memId,
  required int hour,
  DateTime? fixedDate,
}) {
  final date = fixedDate ?? DateTime(2024, 10, 1);
  return savedMemNotification(
    id: id,
    memId: memId,
    type: MemNotificationType.repeat,
    timeOfDaySeconds: hour * 60 * 60,
    message: 'repeat at $hour:00',
    createdAt: date,
    updatedAt: date,
  );
}

MemNotificationEntity repeatAtHourNotificationEntity({
  required int id,
  required int memId,
  required int hour,
  DateTime? fixedDate,
}) =>
    savedRepeatAtHourNotification(
      id: id,
      memId: memId,
      hour: hour,
      fixedDate: fixedDate,
    ).toEntityV2();

MemNotification repeatAtHourMemNotification(int memId, int hour) =>
    MemNotification.by(
      memId,
      MemNotificationType.repeat,
      hour * 60 * 60,
      'repeat at $hour:00',
    );

SavedMemNotificationEntityV1 savedAfterActStartedNotification({
  required int id,
  required int memId,
  DateTime? fixedDate,
}) {
  final date = fixedDate ?? DateTime(2024, 10, 1);
  return savedMemNotification(
    id: id,
    memId: memId,
    type: MemNotificationType.afterActStarted,
    message: 'after act started',
    createdAt: date,
    updatedAt: date,
  );
}

ProviderContainer loadMemListTestContainer({
  TimeOfDay startOfDay = const TimeOfDay(hour: 9, minute: 0),
}) {
  return ProviderContainer(
    overrides: [
      memEntitiesProvider.overrideWith(() => FakeMemEntities()),
      preferenceProvider(startOfDayKey)
          .overrideWith(() => FakeStartOfDayPreference(startOfDay)),
    ],
  );
}

ProviderContainer memListTestContainer(
  Iterable<SavedMemEntityV1> mems, {
  Iterable<SavedMemNotificationEntityV1> notifications = const [],
  TimeOfDay startOfDay = const TimeOfDay(hour: 9, minute: 0),
}) {
  return ProviderContainer(
    overrides: [
      preferenceProvider(startOfDayKey)
          .overrideWith(() => FakeStartOfDayPreference(startOfDay)),
      memEntitiesProvider.overrideWith(() => FakeMemEntities(mems)),
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

List<int> sortedMemIds(ProviderContainer container) =>
    container.read(memListProvider).map((mem) => mem.id).toList();
