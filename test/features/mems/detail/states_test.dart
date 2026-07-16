import '../../../entity_factories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_items/mem_item_repository.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'states_test.mocks.dart';

class _FakeMemEntities extends MemEntities {
  final Iterable<MemEntity> _initial;

  _FakeMemEntities(this._initial);

  @override
  Iterable<MemEntity> build() => _initial;
}

SavedMemItemEntityV1 _savedMemItem({
  required int id,
  required int memId,
  String value = 'memo',
}) {
  final now = DateTime(2024, 6, 1);
  return SavedMemItemEntityV1.fromEntityV2(
    MemItemEntity(
      memId,
      MemItemType.memo,
      value,
      id,
      now,
      now,
      null,
    ),
  );
}

MemNotificationEntity _notificationEntity({
  required int id,
  required int memId,
  required MemNotificationType type,
  int? timeOfDaySeconds,
  String message = 'notification',
}) {
  final now = DateTime(2024, 6, 1);
  return MemNotificationEntity(
    memId,
    type,
    timeOfDaySeconds,
    message,
    id,
    now,
    now,
    null,
  );
}

@GenerateMocks([
  MemRepository,
  MemItemRepository,
  MemNotificationRepository,
])
void main() {
  final mockMemRepository = MockMemRepository();
  final mockMemItemRepository = MockMemItemRepository();
  final mockMemNotificationRepository = MockMemNotificationRepository();

  setUp(() {
    reset(mockMemRepository);
    reset(mockMemItemRepository);
    reset(mockMemNotificationRepository);

    MemRepository(mock: mockMemRepository);
    MemItemRepository(mock: mockMemItemRepository);
    MemNotificationRepository(mock: mockMemNotificationRepository);

    when(mockMemItemRepository.ship(memId: anyNamed('memId')))
        .thenAnswer((_) async => []);
    when(mockMemNotificationRepository.ship(
      memId: anyNamed('memId'),
      memIdsIn: anyNamed('memIdsIn'),
    )).thenAnswer((_) async => []);
    when(mockMemRepository.ship(
      id: anyNamed('id'),
      archived: anyNamed('archived'),
      done: anyNamed('done'),
      loadLatestAct: anyNamed('loadLatestAct'),
    )).thenAnswer((_) async => []);
    when(mockMemRepository.shipById(
      any,
      loadLatestAct: anyNamed('loadLatestAct'),
    )).thenThrow(Exception('shipById not stubbed'));
  });

  ProviderContainer containerFor({
    Iterable<MemEntity> mems = const [],
    List<MemItemEntityV1>? memItems,
    List<MemNotificationEntityV1>? memNotifications,
  }) {
    return ProviderContainer(
      overrides: [
        memEntitiesProvider.overrideWith(() => _FakeMemEntities(mems)),
        if (memItems != null)
          memItemsProvider.overrideWith(
            (ref) => ListValueStateNotifier<MemItemEntityV1>(memItems),
          ),
        if (memNotifications != null)
          memNotificationsProvider.overrideWith(
            (ref) =>
                ListValueStateNotifier<MemNotificationEntityV1>(memNotifications),
          ),
      ],
    );
  }

  group('editingMemByMemIdProvider', () {
    test('starts empty and syncs when mem loads', () {
      const memId = 1;
      final container = containerFor();
      addTearDown(container.dispose);

      final before = container.read(editingMemByMemIdProvider(memId));
      expect(before.value.name, '');

      container.read(memEntitiesProvider.notifier).upsert([
        savedMem(id: memId, name: 'Loaded mem'),
      ]);

      final after = container.read(editingMemByMemIdProvider(memId));
      expect(after.value.name, 'Loaded mem');
    });
  });

  group('memItemsByMemIdProvider', () {
    test('uses existing mem item from memItemsProvider', () {
      const memId = 1;
      final existing = _savedMemItem(id: 10, memId: memId, value: 'existing');
      final container = containerFor(memItems: [existing]);
      addTearDown(container.dispose);

      final items = container.read(memItemsByMemIdProvider(memId));

      expect(items.single.value.value, 'existing');
    });

    test('loads items from repository on init', () async {
      const memId = 1;
      final existing = _savedMemItem(id: 10, memId: memId, value: 'existing');
      final shipped = MemItemEntity(
        memId,
        MemItemType.memo,
        'shipped',
        10,
        DateTime(2024, 6, 1),
        DateTime(2024, 6, 1),
        null,
      );
      when(mockMemItemRepository.ship(memId: memId))
          .thenAnswer((_) async => [shipped]);

      final container = containerFor(memItems: [existing]);
      addTearDown(container.dispose);

      container.read(memItemsByMemIdProvider(memId));
      await Future<void>.delayed(Duration.zero);

      final items = container.read(memItemsProvider);
      expect(
        items.whereType<SavedMemItemEntityV1>().map((e) => e.value.value),
        contains('shipped'),
      );
    });
  });

  group('memNotificationsByMemIdProvider', () {
    test('filters notifications by memId', () {
      const memId = 1;
      final now = DateTime(2024, 6, 1);
      final forMem = savedMemNotification(
        id: 1,
        memId: memId,
        type: MemNotificationType.repeat,
        timeOfDaySeconds: 3600,
        message: 'Repeat',
        createdAt: now,
        updatedAt: now,
      );
      final forOther = savedMemNotification(
        id: 2,
        memId: 2,
        type: MemNotificationType.repeat,
        timeOfDaySeconds: 3600,
        message: 'Other',
        createdAt: now,
        updatedAt: now,
      );
      final container = containerFor(memNotifications: [forMem, forOther]);
      addTearDown(container.dispose);

      final notifications = container.read(memNotificationsByMemIdProvider(memId));

      expect(
        notifications.whereType<SavedMemNotificationEntityV1>(),
        hasLength(1),
      );
      expect(notifications.first.value.memId, memId);
    });

    test('loads notifications from repository on init', () async {
      const memId = 1;
      final weekly = MemNotificationEntityV1(
        MemNotification.by(
          memId,
          MemNotificationType.repeatByDayOfWeek,
          7200,
          'Weekly',
        ),
      );
      when(mockMemNotificationRepository.ship(memId: memId)).thenAnswer(
        (_) async => [
          _notificationEntity(
            id: 1,
            memId: memId,
            type: MemNotificationType.repeat,
          ),
          _notificationEntity(
            id: 2,
            memId: memId,
            type: MemNotificationType.repeatByDayOfWeek,
            timeOfDaySeconds: 7200,
          ),
        ],
      );

      final container = containerFor(memNotifications: [weekly]);
      addTearDown(container.dispose);

      container.read(memNotificationsByMemIdProvider(memId));
      await Future<void>.delayed(Duration.zero);

      final notifications = container.read(memNotificationsProvider);
      expect(notifications.whereType<SavedMemNotificationEntityV1>(), hasLength(2));
    });
  });

  group('memRepeatByNDayNotificationByMemIdProvider', () {
    test('selects repeatByNDay notification', () {
      const memId = 1;
      final container = containerFor();
      addTearDown(container.dispose);

      final notification =
          container.read(memRepeatByNDayNotificationByMemIdProvider(memId));

      expect(notification.value.isRepeatByNDay(), isTrue);
    });
  });

  group('memAfterActStartedNotificationByMemIdProvider', () {
    test('selects afterActStarted notification', () {
      const memId = 1;
      final container = containerFor();
      addTearDown(container.dispose);

      final notification =
          container.read(memAfterActStartedNotificationByMemIdProvider(memId));

      expect(notification.value.isAfterActStarted(), isTrue);
    });
  });

  group('memStateProvider', () {
    test('serves mem from repository', () async {
      const memId = 1;
      final entity = MemEntity(
        memId,
        'Test mem',
        null,
        null,
        null,
        DateTime(2024, 6, 1),
        DateTime(2024, 6, 1),
        null,
      );
      when(mockMemRepository.shipById(
        memId,
        loadLatestAct: true,
      )).thenAnswer((_) async => entity);

      final container = containerFor();
      addTearDown(container.dispose);

      final mem = await container.read(memStateProvider(memId).future);

      expect(mem.name, 'Test mem');
    });
  });
}
