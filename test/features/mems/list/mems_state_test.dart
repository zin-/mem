import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/preference/preference_key.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'mems_state_test.mocks.dart';

class _FakePreference extends Preference<TimeOfDay> {
  _FakePreference();

  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 9, minute: 0);
}

MemEntity _memEntity(int id, String name) {
  final now = DateTime(2024, 10, 1);
  return MemEntity(
    id,
    name,
    null,
    null,
    null,
    now,
    now,
    null,
  );
}

MemNotificationEntity _notificationEntity({
  required int id,
  required int memId,
  required int hour,
}) {
  final now = DateTime(2024, 10, 1);
  return MemNotificationEntity(
    memId,
    MemNotificationType.repeat,
    hour * 60 * 60,
    'repeat at $hour:00',
    id,
    now,
    now,
    null,
  );
}

@GenerateMocks([
  MemRepository,
  MemNotificationRepository,
])
void main() {
  final mockMemRepository = MockMemRepository();
  final mockMemNotificationRepository = MockMemNotificationRepository();

  setUp(() {
    reset(mockMemRepository);
    reset(mockMemNotificationRepository);

    MemRepository(mock: mockMemRepository);
    MemNotificationRepository(mock: mockMemNotificationRepository);
  });

  group('loadMemList', () {
    test('preloads saved notifications for notifyAt sort', () async {
      final memA = _memEntity(1, 'Mem A');
      final memB = _memEntity(2, 'Mem B');
      final notificationA = _notificationEntity(id: 1, memId: 1, hour: 12);
      final notificationB = _notificationEntity(id: 2, memId: 2, hour: 8);

      when(mockMemRepository.ship(
        id: anyNamed('id'),
        archived: anyNamed('archived'),
        done: anyNamed('done'),
        loadLatestAct: anyNamed('loadLatestAct'),
      )).thenAnswer((_) async => [memA, memB]);
      when(mockMemNotificationRepository.ship(
        memId: anyNamed('memId'),
        memIdsIn: anyNamed('memIdsIn'),
      )).thenAnswer((_) async => [notificationA, notificationB]);

      final container = ProviderContainer(
        overrides: [
          preferenceProvider(startOfDayKey).overrideWith(() => _FakePreference()),
        ],
      );
      addTearDown(container.dispose);

      container.read(memEntitiesProvider);
      await container.read(memEntitiesProvider.notifier).loadMemList();

      expect(
        container
            .read(memNotificationsProvider)
            .whereType<SavedMemNotificationEntityV1>(),
        hasLength(2),
      );

      verify(mockMemNotificationRepository.ship(
        memId: anyNamed('memId'),
        memIdsIn: argThat(containsAll([1, 2]), named: 'memIdsIn'),
      )).called(2);

      final sortedIds =
          container.read(memListProvider).map((mem) => mem.id).toList();

      expect(sortedIds, [2, 1]);
    });
  });
}
