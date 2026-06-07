import '../../../entity_factories.dart';
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

class _MemEntitiesWithoutAutoLoad extends MemEntities {
  @override
  Iterable<SavedMemEntityV1> build() => [];
}

class _FakePreference extends Preference<TimeOfDay> {
  _FakePreference();

  @override
  TimeOfDay build(PreferenceKey<TimeOfDay> key) =>
      const TimeOfDay(hour: 6, minute: 0);
}

MemEntity _memEntityV2(int id, String name) {
  final fixedDate = DateTime(2024, 10, 1);
  return savedMem(
    id: id,
    name: name,
    createdAt: fixedDate,
    updatedAt: fixedDate,
  ).toEntityV2();
}

MemNotificationEntity _repeatAtHourEntity({
  required int id,
  required int memId,
  required int hour,
}) {
  final fixedDate = DateTime(2024, 10, 1);
  return savedMemNotification(
    id: id,
    memId: memId,
    type: MemNotificationType.repeat,
    timeOfDaySeconds: hour * 60 * 60,
    message: 'repeat at $hour:00',
    createdAt: fixedDate,
    updatedAt: fixedDate,
  ).toEntityV2();
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
      final memA = _memEntityV2(1, 'Mem A');
      final memB = _memEntityV2(2, 'Mem B');
      final notificationA = _repeatAtHourEntity(id: 1, memId: 1, hour: 12);
      final notificationB = _repeatAtHourEntity(id: 2, memId: 2, hour: 8);

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
          memEntitiesProvider
              .overrideWith(() => _MemEntitiesWithoutAutoLoad()),
          preferenceProvider(startOfDayKey).overrideWith(() => _FakePreference()),
        ],
      );
      addTearDown(container.dispose);

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
      )).called(1);

      final sortedIds =
          container.read(memListProvider).map((mem) => mem.id).toList();

      expect(sortedIds, [2, 1]);
    });
  });
}
