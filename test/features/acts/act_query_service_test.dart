import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Act;
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/acts/acts_summary.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/singleton.dart';

void main() {
  group('ActQueryService', () {
    late AppDatabase db;
    late ActQueryService query;

    setUp(() async {
      db = AppDatabase.memory();
      await Migrator(db).createAll();
      DriftDatabaseAccessor.reset();
      Singleton.override<DriftDatabaseAccessor>(
        DriftDatabaseAccessor.withDatabase(db),
      );
      query = ActQueryService();
    });

    tearDown(() async {
      await db.close();
      DriftDatabaseAccessor.reset();
    });

    Future<int> insertMem() async {
      final now = DateTime.now();
      return (await db.into(db.mems).insertReturning(
                MemsCompanion.insert(name: 'm', createdAt: now),
              ))
          .id;
    }

    Future<void> insertAct({
      required int memId,
      required DateTime start,
      String? actKind,
    }) async {
      final now = DateTime.now();
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: memId,
              createdAt: now,
              start: Value(start),
              end: Value(start.add(const Duration(hours: 1))),
              actKind: Value(actKind),
            ),
          );
    }

    test('fetchLatestByMemIds returns latest row regardless of act_kind',
        () async {
      final memId = await insertMem();
      final base = DateTime(2024, 6, 1, 12);
      await insertAct(
        memId: memId,
        start: base,
        actKind: 'finished',
      );
      await insertAct(
        memId: memId,
        start: base.add(const Duration(days: 1)),
        actKind: 'skipped',
      );

      final latest = await query.fetchLatestByMemIds(memId);

      expect(latest?.actKind, ActKind.skipped);
    });

    test('actExcludingSkippedForPerformance omits skipped only', () async {
      final memId = await insertMem();
      await insertAct(memId: memId, start: DateTime(2024, 6, 1, 10));
      await insertAct(
        memId: memId,
        start: DateTime(2024, 6, 2, 10),
        actKind: 'finished',
      );
      await insertAct(
        memId: memId,
        start: DateTime(2024, 6, 3, 10),
        actKind: 'skipped',
      );

      final rows = await (db.select(db.acts)
            ..where(
              (t) =>
                  t.memId.equals(memId) & actExcludingSkippedForPerformance(t),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.start)]))
          .get();

      expect(rows, hasLength(2));
      expect(
        rows.map(ActEntity.fromTuple).map((e) => e.actKind).toSet(),
        {null, ActKind.finished},
      );
    });

    test('fetchPaging includes skipped rows', () async {
      final memId = await insertMem();
      await insertAct(
        memId: memId,
        start: DateTime(2024, 6, 1, 10),
        actKind: 'skipped',
      );

      final page = await query.fetchPaging(memId, 0, 10);

      expect(page.list, hasLength(1));
      expect(page.list.single.actKind, ActKind.skipped);
      expect(page.totalCount, 1);
    });

    test('chart aggregation excludes skipped acts', () async {
      final memId = await insertMem();
      await insertAct(memId: memId, start: DateTime(2024, 6, 1, 10));
      await insertAct(
        memId: memId,
        start: DateTime(2024, 6, 2, 10),
        actKind: 'finished',
      );
      await insertAct(
        memId: memId,
        start: DateTime(2024, 6, 3, 10),
        actKind: 'skipped',
      );

      final rows = await (db.select(db.acts)
            ..where(
              (t) =>
                  t.memId.equals(memId) & actExcludingSkippedForPerformance(t),
            ))
          .get();
      final acts =
          rows.map(ActEntity.fromTuple).map((e) => e.toDomain()).toList();
      final summary = ActsSummary(acts, AggregationType.count);

      expect(acts, hasLength(2));
      expect(summary.getValue(acts), 2);
    });

    test('fetchScheduleAnchorByMemIds returns latest non-skipped act', () async {
      final memId = await insertMem();
      final finishStart = DateTime(2024, 6, 1, 10);
      final skipStart = DateTime(2024, 6, 3, 10);
      await insertAct(
        memId: memId,
        start: finishStart,
        actKind: 'finished',
      );
      await insertAct(
        memId: memId,
        start: skipStart,
        actKind: 'skipped',
      );

      final anchor = await query.fetchScheduleAnchorByMemIds(memId);

      expect(anchor?.actKind, ActKind.finished);
      expect(anchor?.start?.day, finishStart.day);
    });

    test('fetchScheduleAnchorsByMemIds batch returns anchor per skipped mem',
        () async {
      final memId = await insertMem();
      final finishStart = DateTime(2024, 6, 1, 10);
      await insertAct(
        memId: memId,
        start: finishStart,
        actKind: 'finished',
      );
      await insertAct(
        memId: memId,
        start: DateTime(2024, 6, 3, 10),
        actKind: 'skipped',
      );

      final anchors = await query.fetchScheduleAnchorsByMemIds([memId]);

      expect(anchors, hasLength(1));
      expect(anchors[memId]?.actKind, ActKind.finished);
    });

    test(
        'resolveScheduleAnchorForNotifications fetches anchor when latest is skipped',
        () async {
      final memId = await insertMem();
      final finishStart = DateTime(2024, 6, 1, 10);
      final skipStart = DateTime(2024, 6, 3, 10);
      await insertAct(
        memId: memId,
        start: finishStart,
        actKind: 'finished',
      );
      await insertAct(
        memId: memId,
        start: skipStart,
        actKind: 'skipped',
      );

      final latest =
          (await query.fetchLatestByMemIds(memId))?.toDomain();

      final resolved = await query.resolveScheduleAnchorForNotifications(
        memId: memId,
        latestAct: latest,
      );

      expect(resolved?.actKind, ActKind.finished);
      expect(resolved?.period?.start?.day, finishStart.day);
    });

    test('resolveScheduleAnchorForNotifications uses provided anchor', () async {
      final anchor = Act.by(
        1,
        startWhen: DateAndTime(2024, 6, 1),
        endWhen: DateAndTime(2024, 6, 1, 1),
        completionKind: ActKind.finished,
      );
      final latest = Act.by(
        0,
        startWhen: DateAndTime(2024, 6, 3),
        endWhen: DateAndTime(2024, 6, 3, 1),
        completionKind: ActKind.skipped,
      );

      final resolved = await query.resolveScheduleAnchorForNotifications(
        memId: 0,
        latestAct: latest,
        scheduleAnchorAct: anchor,
      );

      expect(resolved, same(anchor));
    });

    test('fetchByMemIdAndPeriod excludes skipped for chart', () async {
      final memId = await insertMem();
      await insertAct(memId: memId, start: DateTime(2024, 6, 1, 10));
      await insertAct(
        memId: memId,
        start: DateTime(2024, 6, 2, 10),
        actKind: 'finished',
      );
      await insertAct(
        memId: memId,
        start: DateTime(2024, 6, 3, 10),
        actKind: 'skipped',
      );

      final period = DateAndTimePeriod(
        start: DateAndTime(2024, 6, 1),
        end: DateAndTime(2024, 6, 5),
      );
      final rows = await query.fetchByMemIdAndPeriod(memId, period);

      expect(rows, hasLength(2));
      expect(
        rows.map((e) => e.actKind).toSet(),
        {null, ActKind.finished},
      );
    });

    test('activeCount counts started acts that have no end', () async {
      final memId = await insertMem();

      expect(await query.activeCount(), 0);

      await insertAct(memId: memId, start: DateTime(2024, 6, 1, 10));
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: memId,
              createdAt: DateTime.now(),
            ),
          );
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: memId,
              createdAt: DateTime.now(),
              start: Value(DateTime(2024, 6, 2, 10)),
            ),
          );
      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: memId,
              createdAt: DateTime.now(),
              start: Value(DateTime(2024, 6, 3, 10)),
            ),
          );

      expect(await query.activeCount(), 2);
    });

    test(
        'fetchLatestAndPausedByMemIds keeps the newest paused start for the given mems',
        () async {
      final memId = await insertMem();
      final otherMemId = await insertMem();
      final pausedAt = DateTime(2024, 6, 1, 9);
      final newest = DateTime(2024, 6, 5, 10);

      Future<void> insertPaused({
        required int memId,
        DateTime? start,
      }) =>
          db.into(db.acts).insert(
                ActsCompanion.insert(
                  memId: memId,
                  createdAt: DateTime.now(),
                  start: Value(start),
                  pausedAt: Value(pausedAt),
                ),
              );

      await db.into(db.acts).insert(
            ActsCompanion.insert(
              memId: memId,
              createdAt: DateTime.now(),
              start: Value(DateTime(2024, 6, 9, 10)),
            ),
          );
      await insertPaused(memId: memId);
      await insertPaused(memId: memId);
      await insertPaused(memId: memId, start: DateTime(2024, 6, 3, 10));
      await insertPaused(memId: memId);
      await insertPaused(memId: memId, start: DateTime(2024, 6, 2, 10));
      await insertPaused(memId: memId, start: newest);
      await insertPaused(
        memId: otherMemId,
        start: DateTime(2024, 6, 8, 10),
      );

      final filtered = await query.fetchLatestAndPausedByMemIds([memId]);

      expect(filtered, hasLength(1));
      expect(filtered.single.memId, memId);
      expect(
        filtered.single.start,
        DateAndTime.from(newest, timeOfDay: newest),
      );

      final all = await query.fetchLatestAndPausedByMemIds(null);

      expect(all.map((act) => act.memId).toSet(), {memId, otherMemId});
      expect(
        all.singleWhere((act) => act.memId == memId).start,
        DateAndTime.from(newest, timeOfDay: newest),
      );
    });

    test(
        'fetchByMemIdAndPeriod with null period returns non-skipped acts regardless of date',
        () async {
      final memId = await insertMem();
      final otherMemId = await insertMem();
      final early = DateTime(2020, 1, 1, 10);
      final later = DateTime(2026, 12, 31, 10);
      await insertAct(memId: memId, start: early);
      await insertAct(
        memId: memId,
        start: later,
        actKind: 'finished',
      );
      await insertAct(
        memId: memId,
        start: DateTime(2024, 6, 3, 10),
        actKind: 'skipped',
      );
      await insertAct(
        memId: otherMemId,
        start: DateTime(2024, 6, 2, 10),
        actKind: 'finished',
      );

      final rows = await query.fetchByMemIdAndPeriod(memId, null);

      expect(rows, hasLength(2));
      expect(rows.map((e) => e.memId).toSet(), {memId});
      expect(
        rows.map((e) => e.actKind).toSet(),
        {null, ActKind.finished},
      );
      expect(
        rows.map((e) => e.start?.year).toSet(),
        {early.year, later.year},
      );
    });
  });
}
