import '../../../entity_factories.dart';
import 'helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'mems_state_test.mocks.dart';

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
      final fixedDate = DateTime(2024, 10, 1);
      final memA = savedMem(
        id: 1,
        name: 'Mem A',
        createdAt: fixedDate,
        updatedAt: fixedDate,
      ).toEntityV2();
      final memB = savedMem(
        id: 2,
        name: 'Mem B',
        createdAt: fixedDate,
        updatedAt: fixedDate,
      ).toEntityV2();
      final notificationA = repeatAtHourNotificationEntity(
        id: 1,
        memId: 1,
        hour: 12,
        fixedDate: fixedDate,
      );
      final notificationB = repeatAtHourNotificationEntity(
        id: 2,
        memId: 2,
        hour: 8,
        fixedDate: fixedDate,
      );

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

      final container = loadMemListTestContainer(
        startOfDay: const TimeOfDay(hour: 6, minute: 0),
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

      expect(sortedMemIds(container), [2, 1]);
    });
  });
}
