import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Act;
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/acts/act_repository.dart';
import 'package:mem/features/acts/act_service.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  group('Act skip integration', () {
    late AppDatabase db;
    late ActService service;
    late ActQueryService query;
    late ActRepository repository;

    final startOfToday = DateTime(2024, 10, 12);
    final repeatByNDayNotifications = [
      MemNotification.by(
        0,
        MemNotificationType.repeatByNDay,
        2,
        'repeat by 2 day',
      ),
    ];

    setUp(() async {
      db = AppDatabase.memory();
      await Migrator(db).createAll();
      DriftDatabaseAccessor.reset();
      Singleton.reset<ActRepository>();
      ActService.resetSingleton();
      Singleton.override<DriftDatabaseAccessor>(
        DriftDatabaseAccessor.withDatabase(db),
      );
      query = ActQueryService();
      repository = ActRepository();
      service = ActService(
        actRepository: repository,
        actQueryService: query,
      );
    });

    tearDown(() async {
      await db.close();
      DriftDatabaseAccessor.reset();
      Singleton.reset<ActRepository>();
      ActService.resetSingleton();
    });

    Future<int> insertMem() async {
      final now = DateTime.now();
      return (await db.into(db.mems).insertReturning(
            MemsCompanion.insert(name: 'm', createdAt: now),
          ))
          .id;
    }

    Future<DateTime?> nextNotifyAtForLatest(int memId) async {
      final latest = await query.fetchLatestByMemIds(memId);
      return MemNotification.nextNotifyAt(
        repeatByNDayNotifications,
        startOfToday,
        latest?.toDomain(),
      );
    }

    Future<Act?> latestActForMem(int memId) async {
      final rows = await MemRepository().ship(
        id: memId,
        loadLatestAct: true,
      );
      return rows.single.latestAct;
    }

    test(
        'skip after weekly finish keeps nextNotifyAt at today not skip plus 7 days',
        () async {
      final finishDay = DateAndTime(2024, 10, 5, 12, 0);
      final skipDay = DateAndTime(2024, 10, 11, 12, 0);
      final weeklyRepeatNotifications = [
        MemNotification.by(
          0,
          MemNotificationType.repeatByNDay,
          7,
          'repeat by 7 day',
        ),
      ];
      final memId = await insertMem();

      await service.finish(memId, finishDay);
      await service.skip(memId, skipDay);

      final latest = await query.fetchLatestByMemIds(memId);
      expect(latest?.actKind, ActKind.skipped);

      final nextNotify = MemNotification.nextNotifyAt(
        weeklyRepeatNotifications,
        startOfToday,
        latest?.toDomain(),
      );

      expect(
        nextNotify,
        DateTime(startOfToday.year, startOfToday.month, startOfToday.day),
      );
    });

    test('skip and finish at same time yield same nextNotifyAt', () async {
      final when = DateAndTime(2024, 10, 11, 12, 0);
      final skipMemId = await insertMem();
      final finishMemId = await insertMem();

      await service.skip(skipMemId, when);
      await service.finish(finishMemId, when);

      final skippedNotify = await nextNotifyAtForLatest(skipMemId);
      final finishedNotify = await nextNotifyAtForLatest(finishMemId);

      expect(skippedNotify, finishedNotify);
      expect(
        skippedNotify,
        DateTime(startOfToday.year, startOfToday.month, startOfToday.day + 1),
      );
    });

    test('deleting skipped act reverts schedule anchor to previous act', () async {
      final memId = await insertMem();
      final day1 = DateAndTime(2024, 10, 10, 12, 0);
      final day2 = DateAndTime(2024, 10, 11, 12, 0);

      await service.finish(memId, day1);
      final skipped = await service.skip(memId, day2);

      final latestBeforeDelete = await latestActForMem(memId);
      expect(latestBeforeDelete?.actKind, ActKind.skipped);
      expect(latestBeforeDelete?.period?.start?.day, day2.day);
      expect(await nextNotifyAtForLatest(memId), isNotNull);

      await repository.waste(id: skipped.id);

      final previous = await query.fetchLatestByMemIds(memId);
      expect(previous?.actKind, ActKind.finished);
      expect(previous?.start?.day, day1.day);
      final latestAfterDelete = await latestActForMem(memId);
      expect(latestAfterDelete?.actKind, ActKind.finished);
      expect(latestAfterDelete?.period?.start?.day, day1.day);
      expect(
        await nextNotifyAtForLatest(memId),
        DateTime(startOfToday.year, startOfToday.month, startOfToday.day),
      );
    });

    test('editing skipped act start updates schedule anchor', () async {
      final memId = await insertMem();
      final day1 = DateAndTime(2024, 10, 10, 12, 0);
      final day2 = DateAndTime(2024, 10, 11, 12, 0);
      final day4 = DateAndTime(2024, 10, 14, 12, 0);

      await service.finish(memId, day1);
      final skipped = await service.skip(memId, day2);

      final edited = skipped.updatedWith(
        Act.by(
          memId,
          startWhen: day4,
          endWhen: day4,
          completionKind: ActKind.skipped,
        ),
      );
      await service.edit(edited);

      final latest = await query.fetchLatestByMemIds(memId);
      expect(latest?.start?.day, day4.day);
      expect(latest?.actKind, ActKind.skipped);
      expect(
        await nextNotifyAtForLatest(memId),
        DateTime(2024, 10, 16),
      );
    });

    test('act list paging includes skipped rows', () async {
      final memId = await insertMem();
      await service.finish(memId, DateAndTime(2024, 10, 10, 12, 0));
      await service.skip(memId, DateAndTime(2024, 10, 11, 12, 0));

      final page = await query.fetchPaging(memId, 0, 10);

      expect(page.list, hasLength(2));
      expect(page.list.first.actKind, ActKind.skipped);
      expect(page.list.last.actKind, ActKind.finished);
    });

    test('skip in place replaces active act with skipped', () async {
      final memId = await insertMem();
      final start = DateAndTime(2024, 10, 11, 9, 0);
      final end = DateAndTime(2024, 10, 11, 10, 0);

      await service.start(memId, start);
      final skipped = await service.skip(memId, end);

      expect(skipped.actKind, ActKind.skipped);
      expect(skipped.start?.hour, 9);
      expect(skipped.end?.hour, 10);
      final latest = await query.fetchLatestByMemIds(memId);
      expect(latest?.id, skipped.id);
      expect(latest?.actKind, ActKind.skipped);
    });

    test('skip throws when latest is paused', () async {
      final memId = await insertMem();
      final now = DateTime(2024, 10, 11, 12, 0);
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: memId,
              createdAt: now,
              pausedAt: Value(now),
            ),
          );

      await expectLater(
        service.skip(memId, DateAndTime.from(now)),
        throwsA(isA<StateError>()),
      );
    });
  });
}
