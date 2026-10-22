import '../../../entity_factories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
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
  MemNotificationRepository,
])
void main() {
  final mockMemRepository = MockMemRepository();
  final mockMemNotificationRepository = MockMemNotificationRepository();

  void whenShip({int? id, List<MemEntity> mems = const []}) {
    when(mockMemRepository.ship(
      id: id ?? anyNamed('id'),
      archived: anyNamed('archived'),
      done: anyNamed('done'),
      offset: anyNamed('offset'),
      limit: anyNamed('limit'),
      loadLatestAct: anyNamed('loadLatestAct'),
    )).thenAnswer((_) async => mems);
  }

  setUp(() {
    reset(mockMemRepository);
    reset(mockMemNotificationRepository);

    MemRepository(mock: mockMemRepository);
    MemNotificationRepository(mock: mockMemNotificationRepository);

    whenShip();
    when(mockMemNotificationRepository.ship(
      memId: anyNamed('memId'),
      memIdsIn: anyNamed('memIdsIn'),
    )).thenAnswer((_) async => []);
    when(mockMemRepository.shipById(
      any,
      loadLatestAct: anyNamed('loadLatestAct'),
    )).thenThrow(Exception('shipById not stubbed'));
  });

  ProviderContainer containerFor({
    Iterable<MemEntity> mems = const [],
    List<MemNotificationEntityV1>? memNotifications,
  }) {
    return ProviderContainer(
      overrides: [
        memEntitiesProvider.overrideWith(() => _FakeMemEntities(mems)),
        if (memNotifications != null)
          memNotificationsProvider.overrideWith(
            (ref) => ListValueStateNotifier<MemNotificationEntityV1>(
                memNotifications),
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
    test('uses existing mem item from MemEntity.items', () {
      const memId = 1;
      final existing = _savedMemItem(id: 10, memId: memId, value: 'existing');
      final container = containerFor(
        mems: [
          savedMem(id: memId, name: 'cached').updatedWith(
            items: () => [existing.toEntityV2()],
          ),
        ],
      );
      addTearDown(container.dispose);

      final items = container.read(memItemsByMemIdProvider(memId));

      expect(items.single, isA<SavedMemItemEntityV1>());
      expect((items.single as SavedMemItemEntityV1).id, existing.id);
      expect(items.single.value.value, 'existing');
    });

    test('does not keep memo after new mem editing is disposed', () async {
      final container = containerFor();
      addTearDown(container.dispose);

      final sub = container.listen(memItemsByMemIdProvider(null), (_, __) {});
      final current = container.read(memItemsByMemIdProvider(null)).single;
      container.read(memItemsByMemIdProvider(null).notifier).upsertAll(
        [current.copiedWith(value: () => 'previous memo')],
        (a, b) => a.value.type == b.value.type,
      );

      expect(
        container.read(memItemsByMemIdProvider(null)).single.value.value,
        'previous memo',
      );

      sub.close();
      await container.pump();

      expect(
        container.read(memItemsByMemIdProvider(null)).single.value.value,
        '',
      );
    });

    test('does not ship when saved items are already on the mem', () async {
      const memId = 1;
      final existing = _savedMemItem(id: 10, memId: memId, value: 'existing');
      final mem = savedMem(id: memId, name: 'cached').updatedWith(
        items: () => [existing.toEntityV2()],
      );
      final shipped = savedMem(id: memId, name: 'cached').updatedWith(
        items: () => [
          _savedMemItem(id: 10, memId: memId, value: 'shipped').toEntityV2(),
        ],
      );
      whenShip(id: memId, mems: [shipped]);
      when(mockMemRepository.shipById(
        memId,
        loadLatestAct: anyNamed('loadLatestAct'),
      )).thenAnswer((_) async => shipped);

      final container = containerFor(mems: [mem]);
      addTearDown(container.dispose);

      final sub = container.listen(memItemsByMemIdProvider(memId), (_, __) {});
      addTearDown(sub.close);
      await container.pump();

      verifyNever(mockMemRepository.ship(
        id: memId,
        archived: anyNamed('archived'),
        done: anyNamed('done'),
        offset: anyNamed('offset'),
        limit: anyNamed('limit'),
        loadLatestAct: anyNamed('loadLatestAct'),
      ));
      verifyNever(mockMemRepository.shipById(
        memId,
        loadLatestAct: anyNamed('loadLatestAct'),
      ));
      expect(
        container.read(memEntitiesProvider).single.items!.single.value,
        'existing',
      );
      expect(
        container.read(memItemsByMemIdProvider(memId)).single.value.value,
        'existing',
      );
    });

    test('copies loaded mem items into the draft once when none are cached',
        () async {
      const memId = 1;
      final shipped = MemItemEntity(
        memId,
        MemItemType.memo,
        'shipped',
        10,
        DateTime(2024, 6, 1),
        DateTime(2024, 6, 1),
        null,
      );
      when(mockMemRepository.shipById(
        memId,
        loadLatestAct: true,
      )).thenAnswer(
        (_) async => savedMem(id: memId, name: 'loaded').updatedWith(
          items: () => [shipped],
        ),
      );

      final container = containerFor();
      addTearDown(container.dispose);

      final sub = container.listen(memItemsByMemIdProvider(memId), (_, __) {});
      addTearDown(sub.close);

      expect(
        container.read(memItemsByMemIdProvider(memId)).single.value.value,
        '',
      );

      await container.pump();

      expect(
        container.read(memEntitiesProvider).single.items!.single.value,
        'shipped',
      );
      final copied = container.read(memItemsByMemIdProvider(memId)).single;
      expect(copied, isA<SavedMemItemEntityV1>());
      expect((copied as SavedMemItemEntityV1).id, shipped.id);
      expect(copied.value.value, 'shipped');

      container.read(memItemsByMemIdProvider(memId).notifier).upsertAll(
        [copied.copiedWith(value: () => 'editing')],
        (item, updating) => item.value.type == updating.value.type,
      );
      container.read(memEntitiesProvider.notifier).upsert([
        container.read(memEntitiesProvider).single.updatedWith(
              items: () => [
                _savedMemItem(id: shipped.id, memId: memId, value: 'later')
                    .toEntityV2(),
              ],
            ),
      ]);

      expect(
        container.read(memItemsByMemIdProvider(memId)).single.value.value,
        'editing',
      );
      expect(
        container.read(memEntitiesProvider).single.items!.single.value,
        'later',
      );
      verify(mockMemRepository.shipById(
        memId,
        loadLatestAct: true,
      )).called(1);
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

      final notifications =
          container.read(memNotificationsByMemIdProvider(memId));

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
      expect(notifications.whereType<SavedMemNotificationEntityV1>(),
          hasLength(2));
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
