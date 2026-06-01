import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:mem/databases/child_fk_cascade.dart';
import 'package:mem/databases/database.dart' as drift_schema;
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/framework/singleton.dart';
import 'package:mem/features/logger/log_service.dart';

const _latestActPerMemChunkSize = 900;

class MemRepository extends DriftRepository {
  Future<List<MemEntity>> ship({
    int? id,
    bool? archived,
    bool? done,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
    bool loadLatestAct = false,
  }) =>
      v(
        () async {
          late final List<MemEntity> entities;
          if (_usesAccessorShip(
            groupBy: groupBy,
            orderBy: orderBy,
          )) {
            final rows = await driftAccessor.selectEntities(
              defTableMems,
              condition: _shipCondition(
                id: id,
                archived: archived,
                done: done,
              ),
              groupBy: groupBy,
              orderBy: orderBy,
              offset: offset,
              limit: limit,
            );
            entities = List<MemEntity>.from(rows);
          } else {
            var query = driftDb.select(driftDb.mems);
            if (id != null) {
              query = query..where((t) => t.id.equals(id));
            }
            if (archived == true) {
              query = query..where((t) => t.archivedAt.isNotNull());
            } else if (archived == false) {
              query = query..where((t) => t.archivedAt.isNull());
            }
            if (done == true) {
              query = query..where((t) => t.doneAt.isNotNull());
            } else if (done == false) {
              query = query..where((t) => t.doneAt.isNull());
            }
            if (limit != null || offset != null) {
              query = query
                ..limit(limit ?? 999999999, offset: offset ?? 0);
            }
            final rows = await query.get();
            entities = rows.map(MemEntity.fromTuple).toList();
          }

          if (!loadLatestAct || entities.isEmpty) {
            return entities;
          }
          return _attachLatestActs(entities);
        },
        {
          'id': id,
          'archived': archived,
          'done': done,
          'groupBy': groupBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
          'loadLatestAct': loadLatestAct,
        },
      );

  Future<MemEntity> shipById(
    int id, {
    bool loadLatestAct = false,
  }) =>
      v(
        () async {
          final rows = await ship(
            id: id,
            loadLatestAct: loadLatestAct,
          );
          return rows.single;
        },
        {'id': id, 'loadLatestAct': loadLatestAct},
      );

  Future<MemEntity> receive(Mem domain) => v(
        () async {
          final inserted = await driftDb.into(driftDb.mems).insertReturning(
                convertIntoMemsInsertable(domain, DateTime.now()),
              );
          return MemEntity.fromTuple(inserted);
        },
        {'domain': domain},
      );

  Future<MemEntity> replace(MemEntity entity) => v(
        () async {
          final updated = await (driftDb.update(driftDb.mems)
                ..where((t) => t.id.equals(entity.id)))
              .writeReturning(convertIntoMemsUpdateable(entity));
          return MemEntity.fromTuple(updated.single);
        },
        {'entity': entity},
      );

  Future<List<MemEntity>> waste({int? id}) => v(
        () async {
          var selectQuery = driftDb.select(driftDb.mems);
          if (id != null) {
            selectQuery = selectQuery..where((t) => t.id.equals(id));
          }
          final memIds = (await selectQuery.get()).map((r) => r.id).toList();
          await wasteChildRowsReferencingMemIds(driftDb, memIds);

          var deleteQuery = driftDb.delete(driftDb.mems);
          if (id != null) {
            deleteQuery = deleteQuery..where((t) => t.id.equals(id));
          }
          final deleted = await deleteQuery.goAndReturn();
          return deleted.map(MemEntity.fromTuple).toList();
        },
        {'id': id},
      );

  static bool _usesAccessorShip({
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
  }) =>
      groupBy != null || (orderBy != null && orderBy.isNotEmpty);

  static Condition? _shipCondition({
    int? id,
    bool? archived,
    bool? done,
  }) =>
      And(
        [
          if (id != null) Equals(defPkId, id),
          if (archived != null)
            archived
                ? IsNotNull(defColArchivedAt.name)
                : IsNull(defColArchivedAt.name),
          if (done != null)
            done
                ? IsNotNull(defColMemsDoneAt.name)
                : IsNull(defColMemsDoneAt.name),
        ],
      );

  Future<List<MemEntity>> _attachLatestActs(List<MemEntity> mems) async {
    final latestByMemId = await _latestActRowsByMemId(mems.map((m) => m.id));
    return mems
        .map((m) {
          final row = latestByMemId[m.id];
          if (row == null) return m;
          return m.updatedWith(
            latestAct: () => ActEntity.fromTuple(row).toDomain(),
          );
        })
        .toList();
  }

  Future<Map<int, drift_schema.Act>> _latestActRowsByMemId(
    Iterable<int> memIds,
  ) async {
    final list = memIds.toSet().toList();
    if (list.isEmpty) return {};
    final out = <int, drift_schema.Act>{};
    for (var i = 0; i < list.length; i += _latestActPerMemChunkSize) {
      final end = math.min(i + _latestActPerMemChunkSize, list.length);
      final chunk = list.sublist(i, end);
      for (final entry in (await _selectLatestActsChunk(chunk)).entries) {
        out[entry.key] = entry.value;
      }
    }
    return out;
  }

  Future<Map<int, drift_schema.Act>> _selectLatestActsChunk(
    List<int> memIdsChunk,
  ) async {
    if (memIdsChunk.isEmpty) return {};
    final placeholders = List.filled(memIdsChunk.length, '?').join(',');
    final vars = <drift.Variable<Object>>[
      ...memIdsChunk.map((id) => drift.Variable<int>(id)),
    ];

    final sql = '''
WITH ranked AS (
  SELECT
    id AS id,
    mem_id AS mem_id,
    ROW_NUMBER() OVER (
      PARTITION BY mem_id
      ORDER BY COALESCE(start, created_at) DESC, id DESC
    ) AS _rn
  FROM acts
  WHERE mem_id IN ($placeholders)
)
SELECT id
FROM ranked r
WHERE r._rn = 1
''';

    final rawRows = await driftDb.customSelect(sql, variables: vars).get();
    final ids = rawRows.map((row) => row.read<int>('id')).toList();
    if (ids.isEmpty) return {};

    final acts = await (driftDb.select(driftDb.acts)
          ..where((t) => t.id.isIn(ids)))
        .get();
    return {for (final a in acts) a.memId: a};
  }

  MemRepository._();

  factory MemRepository({MemRepository? mock}) {
    if (mock != null) {
      Singleton.override<MemRepository>(mock);
      return mock;
    }
    return Singleton.of(() => MemRepository._());
  }
}
