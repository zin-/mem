import 'package:drift/drift.dart';
import 'package:mem/databases/database.dart';
import 'package:mem/databases/database.dart' as drift_schema;
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_service.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/singleton.dart';

Expression<bool> actExcludingSkippedForPerformance(Acts t) =>
    t.actKind.isNull() | t.actKind.equals(ActKind.skipped.name).not();

class ActQueryService {
  AppDatabase get _db => DriftDatabaseAccessor().driftDatabase;

  Future<int> countByMemIdIs(MemId memId) => v(
        () async {
          final countExpr = countAll();
          final query = _db.selectOnly(_db.acts)..addColumns([countExpr]);
          if (memId != null) {
            query.where(_db.acts.memId.equals(memId));
          }
          final row = await query.getSingle();
          return row.read(countExpr) ?? 0;
        },
        {
          'memId': memId,
        },
      );

  Future<int> activeCount() => v(
        () async {
          final countExpr = countAll();
          final row = await (_db.selectOnly(_db.acts)
                ..addColumns([countExpr])
                ..where(
                  _db.acts.start.isNotNull() & _db.acts.end.isNull(),
                ))
              .getSingle();
          return row.read(countExpr) ?? 0;
        },
      );

  Future<List<ActEntity>> fetchLatestAndPausedByMemIds(Iterable<int>? memIds) =>
      v(
        () async {
          var query = _db.select(_db.acts)
            ..where((t) => t.pausedAt.isNotNull());
          if (memIds != null) {
            query = query..where((t) => t.memId.isIn(memIds));
          }
          final rows = await query.get();
          final latestByMemId = <int, drift_schema.Act>{};
          for (final row in rows) {
            final existing = latestByMemId[row.memId];
            final rowStart = row.start;
            if (existing == null) {
              latestByMemId[row.memId] = row;
              continue;
            }
            final existingStart = existing.start;
            if (existingStart == null) {
              latestByMemId[row.memId] = row;
              continue;
            }
            if (rowStart == null) continue;
            if (rowStart.isAfter(existingStart)) {
              latestByMemId[row.memId] = row;
            }
          }
          return latestByMemId.values.map(ActEntity.fromTuple).toList();
        },
        {'memIds': memIds},
      );

  Future<ActEntity?> fetchLatestByMemIds(int memId) => v(
        () async {
          final rows = await (_db.select(_db.acts)
                ..where((t) => t.memId.equals(memId))
                ..orderBy([(t) => OrderingTerm.desc(t.start)])
                ..limit(1))
              .get();
          return rows.isEmpty ? null : ActEntity.fromTuple(rows.first);
        },
        {'memId': memId},
      );

  Future<ListWithTotalCount<ActEntity>> fetchPaging(
    int? memId,
    int offset,
    int limit,
  ) =>
      v(
        () async {
          var query = _db.select(_db.acts);
          if (memId != null) {
            query = query..where((t) => t.memId.equals(memId));
          }
          final rows = await (query
                ..orderBy([(t) => OrderingTerm.desc(t.start)])
                ..limit(limit, offset: offset))
              .get();
          return ListWithTotalCount(
            rows.map(ActEntity.fromTuple).toList(),
            await countByMemIdIs(memId),
          );
        },
        {
          'memId': memId,
          'offset': offset,
          'limit': limit,
        },
      );

  Future<List<ActEntity>> fetchByMemIdAndPeriod(
    int memId,
    DateAndTimePeriod period,
  ) =>
      v(
        () async {
          final rows = await (_db.select(_db.acts)
                ..where(
                  (t) =>
                      t.memId.equals(memId) &
                      t.start.isBiggerOrEqualValue(period.start!) &
                      t.start.isSmallerThanValue(period.end!) &
                      actExcludingSkippedForPerformance(t),
                ))
              .get();
          return rows.map(ActEntity.fromTuple).toList();
        },
        {
          'memId': memId,
          'period': period,
        },
      );

  ActQueryService._();

  factory ActQueryService() => Singleton.of(() => ActQueryService._());
}
