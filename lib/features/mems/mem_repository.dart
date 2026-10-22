import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:mem/databases/child_fk_cascade.dart';
import 'package:mem/databases/database.dart' as drift_schema;
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_items/mem_item_repository.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/singleton.dart';
import 'package:mem/features/logger/log_service.dart';

const _latestActPerMemChunkSize = 900;

class MemRepository extends DriftRepository {
  Future<List<MemEntity>> ship({
    int? id,
    bool? archived,
    bool? done,
    int? offset,
    int? limit,
    bool loadLatestAct = false,
  }) =>
      v(
        () async {
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
            query = query..limit(limit ?? 999999999, offset: offset ?? 0);
          }
          final rows = await query.get();
          final entities = await _attachItems(rows);

          if (!loadLatestAct || entities.isEmpty) {
            return entities;
          }
          return _attachLatestActs(entities);
        },
        {
          'id': id,
          'archived': archived,
          'done': done,
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

  Future<MemEntity> receive(
    Mem domain, {
    List<MemItem> items = const <MemItem>[],
  }) =>
      v(
        () async {
          final inserted = await driftDb.into(driftDb.mems).insertReturning(
                convertIntoMemsInsertable(domain, DateTime.now()),
              );
          final savedItems = await _insertItems(inserted.id, items);
          return MemEntity.fromTuple(inserted).updatedWith(
            items: () => savedItems,
          );
        },
        {
          'domain': domain,
          'items': items,
        },
      );

  Future<MemEntity> replace(
    MemEntity entity, {
    List<MemItem> receivingItems = const <MemItem>[],
  }) =>
      v(
        () async {
          final updated = await (driftDb.update(driftDb.mems)
                ..where((t) => t.id.equals(entity.id)))
              .writeReturning(convertIntoMemsUpdateable(entity));
          final saved = MemEntity.fromTuple(updated.single);
          if (entity.items == null && receivingItems.isEmpty) {
            return saved;
          }
          final savedItems = [
            if (entity.items != null)
              ...await _updateItems(saved.id, entity.items!),
            ...await _insertItems(saved.id, receivingItems),
          ];
          return saved.updatedWith(items: () => savedItems);
        },
        {
          'entity': entity,
          'receivingItems': receivingItems,
        },
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

  Future<List<MemEntity>> _attachItems(List<drift_schema.Mem> rows) async {
    if (rows.isEmpty) return [];
    final itemsByMemId = await _itemsByMemId(rows.map((row) => row.id));
    return [
      for (final row in rows)
        MemEntity.fromTuple(
          row,
          children: {
            'mem_items': itemsByMemId[row.id] ?? const <MemItemEntity>[],
          },
        ),
    ];
  }

  Future<Map<int, List<MemItemEntity>>> _itemsByMemId(
    Iterable<int> memIds,
  ) async {
    final list = memIds.toSet().toList();
    if (list.isEmpty) return {};
    final out = <int, List<MemItemEntity>>{};
    for (var i = 0; i < list.length; i += _latestActPerMemChunkSize) {
      final end = math.min(i + _latestActPerMemChunkSize, list.length);
      final chunk = list.sublist(i, end);
      final rows = await (driftDb.select(driftDb.memItems)
            ..where((t) => t.memId.isIn(chunk)))
          .get();
      for (final row in rows) {
        (out[row.memId] ??= []).add(MemItemEntity.fromTuple(row));
      }
    }
    return out;
  }

  Future<List<MemItemEntity>> _updateItems(
    int memId,
    List<MemItemEntity> items,
  ) {
    if (items.isEmpty) return Future.value([]);
    final repository = MemItemRepository();
    return Future.wait(
      items.map(
        (item) => repository.replace(
          MemItemEntity(
            memId,
            item.type,
            item.value,
            item.id,
            item.createdAt,
            item.updatedAt,
            item.archivedAt,
          ),
        ),
      ),
    );
  }

  Future<List<MemItemEntity>> _insertItems(int memId, List<MemItem> items) {
    if (items.isEmpty) return Future.value([]);
    final repository = MemItemRepository();
    return Future.wait(
      items.map(
        (item) => repository.receive(MemItem(memId, item.type, item.value)),
      ),
    );
  }

  Future<List<MemEntity>> _attachLatestActs(List<MemEntity> mems) async {
    final latestByMemId = await _latestActRowsByMemId(mems.map((m) => m.id));
    final withLatest = mems
        .map((m) {
          final row = latestByMemId[m.id];
          if (row == null) return m;
          return m.updatedWith(
            latestAct: () => ActEntity.fromTuple(row).toDomain(),
          );
        })
        .toList();
    return _attachScheduleAnchorsForSkippedOnly(withLatest);
  }

  Future<List<MemEntity>> _attachScheduleAnchorsForSkippedOnly(
    List<MemEntity> mems,
  ) async {
    final skippedMemIds = mems
        .where((m) => m.latestAct?.isSkipped == true)
        .map((m) => m.id)
        .toList();
    if (skippedMemIds.isEmpty) return mems;

    final anchorsByMemId =
        await ActQueryService().fetchScheduleAnchorsByMemIds(skippedMemIds);

    return mems
        .map((m) {
          if (m.latestAct?.isSkipped != true) return m;
          final anchor = anchorsByMemId[m.id];
          if (anchor == null) return m;
          return m.updatedWith(
            scheduleAnchorAct: () => anchor.toDomain(),
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
