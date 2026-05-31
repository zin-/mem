import 'package:drift/drift.dart' hide isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/acts/acts_summary.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/order_by.dart';
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

    test('fetchLatestByMemIds returns latest row regardless of act_kind', () async {
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

    test('excludingSkippedForPerformanceCondition omits skipped only', () async {
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

      final accessor = DriftDatabaseAccessor();
      final rows = await accessor.selectEntities(
        defTableActs,
        condition: And(
          [
            Equals(defFkActsMemId, memId),
            excludingSkippedForPerformanceCondition(),
          ],
        ),
        orderBy: [Descending(defColActsStart)],
      );

      expect(rows, hasLength(2));
      expect(
        rows.map((e) => (e as ActEntity).actKind).toSet(),
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

      final accessor = DriftDatabaseAccessor();
      final rows = await accessor.selectEntities(
        defTableActs,
        condition: And(
          [
            Equals(defFkActsMemId, memId),
            excludingSkippedForPerformanceCondition(),
          ],
        ),
      );
      final acts = rows.cast<ActEntity>().map((e) => e.toDomain()).toList();
      final summary = ActsSummary(acts, AggregationType.count);

      expect(acts, hasLength(2));
      expect(summary.getValue(acts), 2);
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
  });
}
