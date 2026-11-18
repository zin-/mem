import 'dart:async';

import '../../../entity_factories.dart';
import 'helpers.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mems/list/states.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/mems/mems_state.dart';
import 'package:mem/features/mems/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
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

    when(mockMemRepository.shipParentMemIdsWithUndoneChildren())
        .thenAnswer((_) async => <int>{});
  });

  group('upsertSavedMemNotifications', () {
    test('returns without repository call when ids are absent', () async {
      late Ref ref;
      final container = ProviderContainer(
        overrides: [
          memNotificationsProvider.overrideWith((r) {
            ref = r;
            return ListValueStateNotifier([]);
          }),
        ],
      );
      addTearDown(container.dispose);
      container.read(memNotificationsProvider);

      await upsertSavedMemNotifications(ref);

      verifyNever(mockMemNotificationRepository.ship(
        memId: anyNamed('memId'),
        memIdsIn: anyNamed('memIdsIn'),
      ));
    });

    test('loads notifications when savedMemNotificationsProvider starts empty',
        () async {
      final fixedDate = DateTime(2024, 10, 1);
      final mem = savedMem(
        id: 1,
        name: 'Mem',
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );
      final notification = repeatAtHourNotificationEntity(
        id: 1,
        memId: 1,
        hour: 8,
        fixedDate: fixedDate,
      );

      when(mockMemNotificationRepository.ship(
        memId: anyNamed('memId'),
        memIdsIn: anyNamed('memIdsIn'),
      )).thenAnswer((_) async => [notification]);

      final container = ProviderContainer(
        overrides: [
          memEntitiesProvider.overrideWith(() => FakeMemEntities([mem])),
          preferenceProvider(startOfDayKey)
              .overrideWith(() => FakeStartOfDayPreference()),
        ],
      );
      addTearDown(container.dispose);

      container.read(savedMemNotificationsProvider);
      await Future<void>.delayed(Duration.zero);

      verify(mockMemNotificationRepository.ship(
        memId: anyNamed('memId'),
        memIdsIn: argThat(contains(1), named: 'memIdsIn'),
      )).called(1);
    });
  });

  group('loadMemList', () {
    test('ships archived false and done false by default', () async {
      when(mockMemRepository.ship(
        archived: false,
        done: false,
        loadLatestAct: true,
      )).thenAnswer((_) async => []);
      when(mockMemNotificationRepository.ship(
        memId: anyNamed('memId'),
        memIdsIn: anyNamed('memIdsIn'),
      )).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          memEntitiesProvider.overrideWith(() => FakeMemEntities()),
          preferenceProvider(startOfDayKey)
              .overrideWith(() => FakeStartOfDayPreference()),
        ],
      );
      addTearDown(container.dispose);

      container.listen(memListProvider, (_, __) {});
      await container.read(loadMemListProvider.future);

      verify(mockMemRepository.ship(
        archived: false,
        done: false,
        loadLatestAct: true,
      )).called(1);
    });

    test('ships without archived or done while search is open', () async {
      when(mockMemRepository.ship(
        archived: false,
        done: false,
        loadLatestAct: true,
      )).thenAnswer((_) async => []);
      when(mockMemRepository.ship(
        loadLatestAct: true,
      )).thenAnswer((_) async => []);
      when(mockMemNotificationRepository.ship(
        memId: anyNamed('memId'),
        memIdsIn: anyNamed('memIdsIn'),
      )).thenAnswer((_) async => []);

      final container = ProviderContainer(
        overrides: [
          memEntitiesProvider.overrideWith(() => FakeMemEntities()),
          preferenceProvider(startOfDayKey)
              .overrideWith(() => FakeStartOfDayPreference()),
        ],
      );
      addTearDown(container.dispose);

      container.listen(memListProvider, (_, __) {});
      await container.read(loadMemListProvider.future);

      verify(mockMemRepository.ship(
        archived: false,
        done: false,
        loadLatestAct: true,
      )).called(1);

      container.read(searchTextProvider.notifier).updatedBy('');
      await container.pump();
      await container.read(loadMemListProvider.future);

      container.read(searchTextProvider.notifier).updatedBy('Alp');
      await container.pump();
      await container.read(loadMemListProvider.future);

      verify(mockMemRepository.ship(
        loadLatestAct: true,
      )).called(1);

      container.read(searchTextProvider.notifier).updatedBy(null);
      await container.pump();
      await container.read(loadMemListProvider.future);

      verify(mockMemRepository.ship(
        archived: false,
        done: false,
        loadLatestAct: true,
      )).called(1);
    });

    test('preloads saved notifications for notifyAt sort', () async {
      final fixedDate = DateTime(2024, 10, 1);
      final memA = savedMem(
        id: 1,
        name: 'Mem A',
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );
      final memB = savedMem(
        id: 2,
        name: 'Mem B',
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );
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

    test('ships the given archived and done, and keeps rows that were absent',
        () async {
      final fixedDate = DateTime(2024, 10, 1);
      final active = savedMem(
        id: 1,
        name: 'active',
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );
      final archived = savedMem(
        id: 2,
        name: 'archived',
        createdAt: fixedDate,
        updatedAt: fixedDate,
        archivedAt: fixedDate,
      );
      final renamed = savedMem(
        id: 2,
        name: 'renamed',
        createdAt: fixedDate,
        updatedAt: fixedDate,
        archivedAt: fixedDate,
      );

      when(mockMemRepository.ship(
        archived: false,
        done: false,
        loadLatestAct: true,
      )).thenAnswer((_) async => [active]);
      when(mockMemRepository.ship(
        archived: true,
        done: false,
        loadLatestAct: true,
      )).thenAnswer((_) async => [renamed]);
      when(mockMemNotificationRepository.ship(
        memId: anyNamed('memId'),
        memIdsIn: anyNamed('memIdsIn'),
      )).thenAnswer((_) async => []);

      final container = loadMemListTestContainer();
      addTearDown(container.dispose);
      final notifier = container.read(memEntitiesProvider.notifier);
      notifier.upsert([archived]);

      await notifier.loadMemList(archived: false, done: false);

      expect(
        container.read(memEntitiesProvider).map((mem) => mem.id).toSet(),
        {active.id, archived.id},
      );

      await notifier.loadMemList(archived: true, done: false);

      expect(
        container.read(memEntitiesProvider).map((mem) => mem.name).toSet(),
        {'active', 'renamed'},
      );
      verify(mockMemRepository.ship(
        archived: false,
        done: false,
        loadLatestAct: true,
      )).called(1);
      verify(mockMemRepository.ship(
        archived: true,
        done: false,
        loadLatestAct: true,
      )).called(1);
    });

    test('ships without archived or done when filters are omitted', () async {
      when(mockMemRepository.ship(
        loadLatestAct: true,
      )).thenAnswer((_) async => []);

      final container = loadMemListTestContainer();
      addTearDown(container.dispose);

      await container.read(memEntitiesProvider.notifier).loadMemList();

      verify(mockMemRepository.ship(
        loadLatestAct: true,
      )).called(1);
    });

    test('upserts a response that finishes after a newer call', () async {
      final fixedDate = DateTime(2024, 10, 1);
      final active = savedMem(
        id: 1,
        name: 'active',
        createdAt: fixedDate,
        updatedAt: fixedDate,
      );
      final archived = savedMem(
        id: 2,
        name: 'archived',
        createdAt: fixedDate,
        updatedAt: fixedDate,
        archivedAt: fixedDate,
      );
      final activeResponse = Completer<List<MemEntity>>();
      final archivedResponse = Completer<List<MemEntity>>();

      when(mockMemRepository.ship(
        id: anyNamed('id'),
        archived: anyNamed('archived'),
        done: anyNamed('done'),
        loadLatestAct: anyNamed('loadLatestAct'),
      )).thenAnswer((invocation) {
        final archivedFilter = invocation.namedArguments[#archived] as bool?;
        return archivedFilter == true
            ? archivedResponse.future
            : activeResponse.future;
      });
      when(mockMemNotificationRepository.ship(
        memId: anyNamed('memId'),
        memIdsIn: anyNamed('memIdsIn'),
      )).thenAnswer((_) async => []);

      final container = loadMemListTestContainer();
      addTearDown(container.dispose);
      final notifier = container.read(memEntitiesProvider.notifier);

      final activeCall = notifier.loadMemList(archived: false, done: false);
      final archivedCall = notifier.loadMemList(archived: true, done: false);

      archivedResponse.complete([archived]);
      await archivedCall;
      activeResponse.complete([active]);
      await activeCall;

      expect(
        container.read(memEntitiesProvider).map((mem) => mem.id).toSet(),
        {active.id, archived.id},
      );
    });

    test('keeps a newer latestAct when an earlier loadMemList returns later',
        () async {
      const memId = 1;
      final fixedDate = DateTime(2024, 10, 1);
      // 時。終了より前なので、一覧が返す act は進行中のまま
      final startedHour = 8;
      // 時。開始の1時間後なので、refresh が返す act は終了済み
      final endedHour = 9;
      final active = ActiveAct(
        memId,
        DateAndTime(2024, 10, 1, startedHour),
      );
      final finished = FinishedAct(
        memId,
        DateAndTime(2024, 10, 1, startedHour),
        DateAndTime(2024, 10, 1, endedHour),
        actKind: ActKind.finished,
      );
      final stale = savedMem(
        id: memId,
        name: 'renamed',
        createdAt: fixedDate,
        updatedAt: fixedDate,
        latestAct: active,
      );
      final refreshed = savedMem(
        id: memId,
        name: 'original',
        createdAt: fixedDate,
        updatedAt: fixedDate,
        latestAct: finished,
      );
      final listResponse = Completer<List<MemEntity>>();

      when(mockMemRepository.ship(
        id: anyNamed('id'),
        archived: anyNamed('archived'),
        done: anyNamed('done'),
        loadLatestAct: anyNamed('loadLatestAct'),
      )).thenAnswer((invocation) {
        final id = invocation.namedArguments[#id] as int?;
        if (id == memId) return Future.value([refreshed]);
        return listResponse.future;
      });
      when(mockMemNotificationRepository.ship(
        memId: anyNamed('memId'),
        memIdsIn: anyNamed('memIdsIn'),
      )).thenAnswer((_) async => []);

      final container = loadMemListTestContainer();
      addTearDown(container.dispose);
      final notifier = container.read(memEntitiesProvider.notifier);

      final listCall = notifier.loadMemList(archived: false, done: false);
      await notifier.refreshLatestActForMem(memId);
      listResponse.complete([stale]);
      await listCall;

      final cached = container.read(memEntitiesProvider).single;
      expect(cached.name, 'renamed');
      expect(cached.latestAct, isA<FinishedAct>());
    });

    test('uses the shipped latestAct when loadMemList starts after refresh',
        () async {
      const memId = 1;
      final fixedDate = DateTime(2024, 10, 1);
      // 時。終了より前なので、refresh が返す act はこの時刻に始まっている
      final startedHour = 8;
      // 時。開始の1時間後なので、refresh が返す act は終了済み
      final endedHour = 9;
      // 時。終了の1時間後なので、その後の一覧が返す act は再開している
      final restartedHour = 10;
      final finished = FinishedAct(
        memId,
        DateAndTime(2024, 10, 1, startedHour),
        DateAndTime(2024, 10, 1, endedHour),
        actKind: ActKind.finished,
      );
      final restarted = ActiveAct(
        memId,
        DateAndTime(2024, 10, 1, restartedHour),
      );
      final refreshed = savedMem(
        id: memId,
        name: 'original',
        createdAt: fixedDate,
        updatedAt: fixedDate,
        latestAct: finished,
      );
      final reloaded = savedMem(
        id: memId,
        name: 'renamed',
        createdAt: fixedDate,
        updatedAt: fixedDate,
        latestAct: restarted,
      );
      final listResponse = Completer<List<MemEntity>>();

      when(mockMemRepository.ship(
        id: anyNamed('id'),
        archived: anyNamed('archived'),
        done: anyNamed('done'),
        loadLatestAct: anyNamed('loadLatestAct'),
      )).thenAnswer((invocation) {
        final id = invocation.namedArguments[#id] as int?;
        if (id == memId) return Future.value([refreshed]);
        return listResponse.future;
      });
      when(mockMemNotificationRepository.ship(
        memId: anyNamed('memId'),
        memIdsIn: anyNamed('memIdsIn'),
      )).thenAnswer((_) async => []);

      final container = loadMemListTestContainer();
      addTearDown(container.dispose);
      final notifier = container.read(memEntitiesProvider.notifier);

      await notifier.refreshLatestActForMem(memId);
      final listCall = notifier.loadMemList(archived: false, done: false);
      listResponse.complete([reloaded]);
      await listCall;

      final cached = container.read(memEntitiesProvider).single;
      expect(cached.name, 'renamed');
      expect(cached.latestAct, isA<ActiveAct>());
    });
  });

  group('loadByMemId', () {
    test('keeps a newer latestAct when an earlier loadByMemId returns later',
        () async {
      const memId = 1;
      final fixedDate = DateTime(2024, 10, 1);
      // 時。終了より前なので、先に始まった load が返す act は進行中のまま
      final startedHour = 8;
      // 時。開始の1時間後なので、refresh が返す act は終了済み
      final endedHour = 9;
      final active = ActiveAct(
        memId,
        DateAndTime(2024, 10, 1, startedHour),
      );
      final finished = FinishedAct(
        memId,
        DateAndTime(2024, 10, 1, startedHour),
        DateAndTime(2024, 10, 1, endedHour),
        actKind: ActKind.finished,
      );
      final stale = savedMem(
        id: memId,
        name: 'renamed',
        createdAt: fixedDate,
        updatedAt: fixedDate,
        latestAct: active,
      );
      final refreshed = savedMem(
        id: memId,
        name: 'original',
        createdAt: fixedDate,
        updatedAt: fixedDate,
        latestAct: finished,
      );
      final byIdResponse = Completer<List<MemEntity>>();
      var idShipCount = 0;

      when(mockMemRepository.ship(
        id: anyNamed('id'),
        archived: anyNamed('archived'),
        done: anyNamed('done'),
        loadLatestAct: anyNamed('loadLatestAct'),
      )).thenAnswer((invocation) {
        final id = invocation.namedArguments[#id] as int?;
        if (id != memId) return Future.value(<MemEntity>[]);
        idShipCount += 1;
        // loadByMemId が先に ship する。その次が refresh
        if (idShipCount == 1) return byIdResponse.future;
        return Future.value([refreshed]);
      });

      final container = loadMemListTestContainer();
      addTearDown(container.dispose);
      final notifier = container.read(memEntitiesProvider.notifier);

      final byIdCall = notifier.loadByMemId(memId);
      await notifier.refreshLatestActForMem(memId);
      byIdResponse.complete([stale]);
      await byIdCall;

      final cached = container.read(memEntitiesProvider).single;
      expect(cached.name, 'renamed');
      expect(cached.latestAct, isA<FinishedAct>());
    });

    test('uses the shipped latestAct when loadByMemId starts after refresh',
        () async {
      const memId = 1;
      final fixedDate = DateTime(2024, 10, 1);
      // 時。終了より前なので、refresh が返す act はこの時刻に始まっている
      final startedHour = 8;
      // 時。開始の1時間後なので、refresh が返す act は終了済み
      final endedHour = 9;
      // 時。終了の1時間後なので、その後の load が返す act は再開している
      final restartedHour = 10;
      final finished = FinishedAct(
        memId,
        DateAndTime(2024, 10, 1, startedHour),
        DateAndTime(2024, 10, 1, endedHour),
        actKind: ActKind.finished,
      );
      final restarted = ActiveAct(
        memId,
        DateAndTime(2024, 10, 1, restartedHour),
      );
      final refreshed = savedMem(
        id: memId,
        name: 'original',
        createdAt: fixedDate,
        updatedAt: fixedDate,
        latestAct: finished,
      );
      final reloaded = savedMem(
        id: memId,
        name: 'renamed',
        createdAt: fixedDate,
        updatedAt: fixedDate,
        latestAct: restarted,
      );
      final byIdResponse = Completer<List<MemEntity>>();
      var idShipCount = 0;

      when(mockMemRepository.ship(
        id: anyNamed('id'),
        archived: anyNamed('archived'),
        done: anyNamed('done'),
        loadLatestAct: anyNamed('loadLatestAct'),
      )).thenAnswer((invocation) {
        final id = invocation.namedArguments[#id] as int?;
        if (id != memId) return Future.value(<MemEntity>[]);
        idShipCount += 1;
        // refresh が先に ship する。その次が loadByMemId
        if (idShipCount == 1) return Future.value([refreshed]);
        return byIdResponse.future;
      });

      final container = loadMemListTestContainer();
      addTearDown(container.dispose);
      final notifier = container.read(memEntitiesProvider.notifier);

      await notifier.refreshLatestActForMem(memId);
      final byIdCall = notifier.loadByMemId(memId);
      byIdResponse.complete([reloaded]);
      await byIdCall;

      final cached = container.read(memEntitiesProvider).single;
      expect(cached.name, 'renamed');
      expect(cached.latestAct, isA<ActiveAct>());
    });
  });

  test('reading memEntitiesProvider does not ship', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(memEntitiesProvider);
    await Future<void>.delayed(Duration.zero);

    verifyNever(mockMemRepository.ship(
      id: anyNamed('id'),
      archived: anyNamed('archived'),
      done: anyNamed('done'),
      offset: anyNamed('offset'),
      limit: anyNamed('limit'),
      loadLatestAct: anyNamed('loadLatestAct'),
    ));
  });
}
