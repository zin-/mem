import '../../../entity_factories.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_items/mem_item_repository.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_repository.dart';
import 'package:mem/features/mem_relations/mem_relation_state.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:mem/features/mems/detail/actions.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_client.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_view_data.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mem_service.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target_states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'save_mem_period_test.mocks.dart';

class _FakeMemEntities extends MemEntities {
  final Iterable<MemEntity> _initial;

  _FakeMemEntities(this._initial);

  @override
  Iterable<MemEntity> build() => _initial;
}

class _FakeTargetState extends TargetState {
  final TargetEntityV1 _entity;

  _FakeTargetState(this._entity);

  @override
  Future<TargetEntityV1> build(int? memId) async => _entity;
}

class _FakeMemRelationEntitiesByMemId extends MemRelationEntitiesByMemId {
  final Iterable<MemRelationEntityV1> _entities;

  _FakeMemRelationEntitiesByMemId(this._entities);

  @override
  Future<Iterable<MemRelationEntityV1>> build(int? memId) async => _entities;
}

MemEntity _savedMemEntityWithPeriod(
  int id,
  String name,
  DateAndTimePeriod period,
) =>
    MemEntity(
      id,
      name,
      null,
      period,
      null,
      DateTime(2024, 6, 1),
      DateTime(2024, 6, 1),
      null,
    );

@GenerateMocks([
  MemClient,
  MemRepository,
  MemItemRepository,
  MemNotificationRepository,
  TargetRepository,
  MemRelationRepository,
])
void main() {
  final mockMemClient = MockMemClient();
  final mockMemRepository = MockMemRepository();
  final mockMemItemRepository = MockMemItemRepository();
  final mockMemNotificationRepository = MockMemNotificationRepository();
  final mockTargetRepository = MockTargetRepository();
  final mockMemRelationRepository = MockMemRelationRepository();

  setUp(() {
    reset(mockMemClient);
    reset(mockMemRepository);
    reset(mockMemItemRepository);
    reset(mockMemNotificationRepository);
    reset(mockTargetRepository);
    reset(mockMemRelationRepository);

    MemClient(mock: mockMemClient);
    MemRepository(mock: mockMemRepository);
    MemItemRepository(mock: mockMemItemRepository);
    MemNotificationRepository(mock: mockMemNotificationRepository);

    when(mockMemItemRepository.ship(memId: anyNamed('memId')))
        .thenAnswer((_) async => []);
    when(mockMemNotificationRepository.ship(
      memId: anyNamed('memId'),
      memIdsIn: anyNamed('memIdsIn'),
    )).thenAnswer((_) async => []);
    when(mockMemRepository.replace(any)).thenAnswer(
      (invocation) async =>
          invocation.positionalArguments[0] as MemEntity,
    );
  });

  tearDown(() {
    MemClient.resetSingleton();
  });

  ProviderContainer containerForMem(
    int memId,
    MemEntity mem, {
    List<MemNotificationEntityV1>? notifications,
  }) {
    return ProviderContainer(
      overrides: [
        memEntitiesProvider.overrideWith(() => _FakeMemEntities([mem])),
        if (notifications != null)
          memNotificationsProvider.overrideWith(
            (ref) =>
                ListValueStateNotifier<MemNotificationEntityV1>(notifications),
          ),
        targetStateProvider(memId).overrideWith(
          () => _FakeTargetState(
            TargetEntityV1(
              Target(
                memId: memId,
                targetType: TargetType.equalTo,
                targetUnit: TargetUnit.count,
                value: 0,
                period: Period.aDay,
              ),
            ),
          ),
        ),
        memRelationEntitiesByMemIdProvider(memId).overrideWith(
          () => _FakeMemRelationEntitiesByMemId([]),
        ),
      ],
    );
  }

  group('saveMem period', () {
    test('passes edited period with time to MemClient.save', () async {
      const memId = 1;
      final mem = savedMem(
        id: memId,
        name: 'Test mem',
        notifyOn: DateTime(2024, 6, 1),
        notifyAt: DateTime(2024, 6, 1, 10, 0),
        endOn: DateTime(2024, 6, 2),
      );
      final container = containerForMem(memId, mem);
      addTearDown(container.dispose);

      final editedPeriod = DateAndTimePeriod(
        start: DateAndTime(2024, 6, 1, 14, 30),
        end: DateAndTime(2024, 6, 2),
      );

      container.read(editingMemByMemIdProvider(memId).notifier).updatedBy(
            container.read(editingMemByMemIdProvider(memId)).updatedWith(
                  (m) => Mem(m.id, m.name, m.doneAt, editedPeriod),
                ),
          );

      when(mockMemClient.save(
        any,
        any,
        any,
        any,
        any,
      )).thenAnswer((_) async {
        return (
          (
            <MemItemEntityV1>[],
            null,
            null,
            null,
            _savedMemEntityWithPeriod(memId, mem.name, editedPeriod),
          ),
          null,
        );
      });

      await container.read(saveMem(memId));

      final capturedMem = verify(mockMemClient.save(
        captureAny,
        any,
        any,
        any,
        any,
      )).captured.single as MemViewData;

      expect(capturedMem.value.period?.start?.hour, 14);
      expect(capturedMem.value.period?.start?.minute, 30);
      expect(capturedMem.value.period?.start?.isAllDay, isFalse);
    });

    test('syncs editingMem from saved result after saving existing mem',
        () async {
      const memId = 1;
      final mem = savedMem(
        id: memId,
        name: 'Test mem',
        notifyOn: DateTime(2024, 6, 1),
        notifyAt: DateTime(2024, 6, 1, 10, 0),
        endOn: DateTime(2024, 6, 2),
      );
      final container = containerForMem(memId, mem);
      addTearDown(container.dispose);

      final savedPeriod = DateAndTimePeriod(
        start: DateAndTime(2024, 6, 1, 14, 30),
        end: DateAndTime(2024, 6, 2),
      );
      final savedEntity =
          _savedMemEntityWithPeriod(memId, mem.name, savedPeriod);

      when(mockMemClient.save(
        any,
        any,
        any,
        any,
        any,
      )).thenAnswer((_) async => (
            (
              <MemItemEntityV1>[],
              null,
              null,
              null,
              savedEntity,
            ),
            null,
          ));

      await container.read(saveMem(memId));

      final editingMem = container.read(editingMemByMemIdProvider(memId));

      expect(editingMem.value.period?.start?.hour, 14);
      expect(editingMem.value.period?.start?.minute, 30);
      expect(editingMem.value.period?.start?.isAllDay, isFalse);
    });
  });

  group('saveMem notifications', () {
    test('drops wasted repeatByNDay from memNotificationsProvider', () async {
      const memId = 1;
      const otherMemId = 2;
      final mem = savedMem(id: memId, name: 'Test mem');
      final now = DateTime(2024, 6, 1);
      final repeat = savedMemNotification(
        id: 10,
        memId: memId,
        type: MemNotificationType.repeat,
        timeOfDaySeconds: 9 * 60 * 60,
        message: 'Repeat',
        createdAt: now,
        updatedAt: now,
      );
      final nDay = savedMemNotification(
        id: 11,
        memId: memId,
        type: MemNotificationType.repeatByNDay,
        timeOfDaySeconds: 3,
        message: 'Repeat by N day',
        createdAt: now,
        updatedAt: now,
      );
      final otherNDay = savedMemNotification(
        id: 20,
        memId: otherMemId,
        type: MemNotificationType.repeatByNDay,
        timeOfDaySeconds: 5,
        message: 'Other mem n-day',
        createdAt: now,
        updatedAt: now,
      );
      final container = containerForMem(
        memId,
        mem,
        notifications: [repeat, nDay, otherNDay],
      );
      addTearDown(container.dispose);

      container.read(memNotificationsByMemIdProvider(memId).notifier).upsertAll(
        [
          nDay.updatedWith(
            (v) => MemNotification.by(v.memId, v.type, null, v.message),
          ),
        ],
        (current, updating) => current.value.type == updating.value.type,
      );

      when(mockMemClient.save(
        any,
        any,
        any,
        any,
        any,
      )).thenAnswer((_) async => (
            (
              <MemItemEntityV1>[],
              [repeat.toEntityV2()],
              null,
              null,
              mem,
            ),
            null,
          ));

      await container.read(saveMem(memId));

      final notifications = container.read(memNotificationsProvider);
      expect(
        notifications.where(
          (e) => e.value.memId == memId && e.value.isRepeatByNDay(),
        ),
        isEmpty,
      );
      expect(
        notifications.where(
          (e) => e.value.memId == memId && e.value.isRepeated(),
        ),
        hasLength(1),
      );
      expect(
        notifications.where((e) => e.value.memId == otherMemId),
        hasLength(1),
      );
    });
  });

  MemService memService() => MemService(
        memRepository: mockMemRepository,
        memItemRepository: mockMemItemRepository,
        memNotificationRepository: mockMemNotificationRepository,
        targetRepository: mockTargetRepository,
        memRelationRepository: mockMemRelationRepository,
      );

  void stubSaveDependencies() {
    when(mockMemNotificationRepository.waste(
      memId: anyNamed('memId'),
      type: anyNamed('type'),
    )).thenAnswer((_) async => []);
    when(mockMemNotificationRepository.waste(memId: anyNamed('memId')))
        .thenAnswer((_) async => []);
    when(mockTargetRepository.waste(memId: anyNamed('memId')))
        .thenAnswer((_) async => []);
    when(mockMemRelationRepository.waste(sourceMemId: anyNamed('sourceMemId')))
        .thenAnswer((_) async => []);
  }

  group('MemService.save period', () {
    test('passes timed period to MemRepository.replace', () async {
      const memId = 1;
      final editedPeriod = DateAndTimePeriod(
        start: DateAndTime(2024, 6, 1, 14, 30),
        end: DateAndTime(2024, 6, 2),
      );
      final memEntity = savedMem(
        id: memId,
        name: 'Test mem',
        notifyOn: DateTime(2024, 6, 1),
        notifyAt: DateTime(2024, 6, 1, 10, 0),
        endOn: DateTime(2024, 6, 2),
      ).updatedWith(
        update: (m) => Mem(m.id, m.name, m.doneAt, editedPeriod),
      );

      when(mockMemRepository.shipById(
        memId,
        loadLatestAct: true,
      )).thenAnswer((_) async => memEntity);

      stubSaveDependencies();

      await memService().save((
        MemViewData.fromEntityV2(memEntity),
        <MemItemEntityV1>[],
        <MemNotificationEntityV1>[],
        null,
        null,
      ));

      final replacedEntity = verify(mockMemRepository.replace(captureAny))
          .captured
          .single as MemEntity;

      expect(replacedEntity.period?.start?.hour, 14);
      expect(replacedEntity.period?.start?.minute, 30);
      expect(replacedEntity.period?.start?.isAllDay, isFalse);
    });

    test('all-day period drops notifyAt on replace (12:00 AM path)', () async {
      const memId = 1;
      final memEntity = savedMem(
        id: memId,
        name: 'Test mem',
        notifyOn: DateTime(2024, 6, 1),
        endOn: DateTime(2024, 6, 2),
      );

      when(mockMemRepository.shipById(
        memId,
        loadLatestAct: true,
      )).thenAnswer((_) async => memEntity);

      stubSaveDependencies();

      await memService().save((
        MemViewData.fromEntityV2(memEntity),
        <MemItemEntityV1>[],
        <MemNotificationEntityV1>[],
        null,
        null,
      ));

      final replacedEntity = verify(mockMemRepository.replace(captureAny))
          .captured
          .single as MemEntity;

      expect(replacedEntity.period?.start?.isAllDay, isTrue);
      expect(replacedEntity.period?.start?.hour, 0);
      expect(replacedEntity.period?.start?.minute, 0);
    });

    test('wastes disabled repeatByNDay', () async {
      const memId = 1;
      final memEntity = savedMem(id: memId, name: 'Test mem');
      final now = DateTime(2024, 6, 1);
      final repeat = savedMemNotification(
        id: 10,
        memId: memId,
        type: MemNotificationType.repeat,
        timeOfDaySeconds: 9 * 60 * 60,
        message: 'Repeat',
        createdAt: now,
        updatedAt: now,
      );
      final nDay = savedMemNotification(
        id: 11,
        memId: memId,
        type: MemNotificationType.repeatByNDay,
        timeOfDaySeconds: 3,
        message: 'Repeat by N day',
        createdAt: now,
        updatedAt: now,
      ).updatedWith(
        (v) => MemNotification.by(v.memId, v.type, null, v.message),
      );

      when(mockMemRepository.shipById(
        memId,
        loadLatestAct: true,
      )).thenAnswer((_) async => memEntity);
      when(mockMemNotificationRepository.replace(any)).thenAnswer(
        (invocation) async =>
            invocation.positionalArguments[0] as MemNotificationEntity,
      );

      stubSaveDependencies();

      await memService().save((
        MemViewData.fromEntityV2(memEntity),
        <MemItemEntityV1>[],
        [repeat, nDay],
        null,
        null,
      ));

      verify(mockMemNotificationRepository.waste(
        memId: memId,
        type: MemNotificationType.repeatByNDay,
      )).called(1);
    });
  });
}
