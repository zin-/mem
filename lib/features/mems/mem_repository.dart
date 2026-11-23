import 'dart:math' as math;

import 'package:drift/drift.dart' as drift;
import 'package:mem/databases/child_fk_cascade.dart';
import 'package:mem/databases/database.dart' as drift_schema;
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_query_service.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_parents/mem_parent.dart';
import 'package:mem/features/mem_preposts/mem_prepost.dart';
import 'package:mem/features/mem_preposts/mem_prepost_entity.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';
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

  Future<void> archiveItems(
    int memId, {
    DateTime? archivedAt,
  }) =>
      v(
        () async {
          final time = archivedAt ?? DateTime.now();
          await (driftDb.update(driftDb.memItems)
                ..where((t) => t.memId.equals(memId)))
              .write(
            drift_schema.MemItemsCompanion(
              updatedAt: drift.Value(time),
              archivedAt: drift.Value(time),
            ),
          );
        },
        {
          'memId': memId,
          'archivedAt': archivedAt,
        },
      );

  Future<void> unarchiveItems(int memId) => v(
        () async {
          await (driftDb.update(driftDb.memItems)
                ..where((t) => t.memId.equals(memId)))
              .write(
            drift_schema.MemItemsCompanion(
              updatedAt: drift.Value(DateTime.now()),
              archivedAt: const drift.Value(null),
            ),
          );
        },
        {'memId': memId},
      );

  Future<MemNotificationEntity> receiveRepeatedNotification(
    MemNotification domain,
  ) =>
      v(
        () async {
          final inserted = await driftDb
              .into(driftDb.memRepeatedNotifications)
              .insertReturning(
                convertIntoMemRepeatedNotificationsInsertable(
                  domain,
                  createdAt: DateTime.now(),
                ),
              );
          return MemNotificationEntity.fromTuple(inserted);
        },
        {'domain': domain},
      );

  Future<MemNotificationEntity> replaceRepeatedNotification(
    MemNotificationEntity entity,
  ) =>
      v(
        () async {
          final updated =
              await (driftDb.update(driftDb.memRepeatedNotifications)
                    ..where((t) => t.id.equals(entity.id)))
                  .writeReturning(
            convertIntoMemRepeatedNotificationsUpdateable(entity),
          );
          return MemNotificationEntity.fromTuple(updated.single);
        },
        {'entity': entity},
      );

  Future<List<MemNotificationEntity>> wasteRepeatedNotifications({
    int? memId,
    MemNotificationType? type,
  }) =>
      v(
        () async {
          var query = driftDb.delete(driftDb.memRepeatedNotifications);
          if (memId != null) {
            query = query..where((t) => t.memId.equals(memId));
          }
          if (type != null) {
            query = query..where((t) => t.type.equals(type.name));
          }
          final deleted = await query.goAndReturn();
          return deleted.map(MemNotificationEntity.fromTuple).toList();
        },
        {
          'memId': memId,
          'type': type,
        },
      );

  Future<List<MemPrePostEntity>> shipPrePostsBySourceMemId(
    int? sourceMemId,
  ) =>
      v(
        () async {
          if (sourceMemId == null) return [];
          final bySource = await _prePostsBySourceMemId([sourceMemId]);
          return bySource[sourceMemId] ?? const <MemPrePostEntity>[];
        },
        {'sourceMemId': sourceMemId},
      );

  Future<MemPrePostEntity> receivePrePost(MemPrePost domain) => v(
        () async {
          final inserted =
              await driftDb.into(driftDb.memPrePosts).insertReturning(
                    convertIntoMemPrePostsInsertable(domain),
                  );
          return MemPrePostEntity.fromTuple(inserted);
        },
        {'domain': domain},
      );

  Future<MemPrePostEntity> replacePrePost(MemPrePostEntity entity) => v(
        () async {
          final updated = await (driftDb.update(driftDb.memPrePosts)
                ..where((t) => t.id.equals(entity.id)))
              .writeReturning(convertIntoMemPrePostsUpdateable(entity));
          return MemPrePostEntity.fromTuple(updated.single);
        },
        {'entity': entity},
      );

  Future<List<MemPrePostEntity>> wastePrePosts({int? sourceMemId}) => v(
        () async {
          var query = driftDb.delete(driftDb.memPrePosts);
          if (sourceMemId != null) {
            query = query..where((t) => t.sourceMemId.equals(sourceMemId));
          }
          final deleted = await query.goAndReturn();
          return deleted.map(MemPrePostEntity.fromTuple).toList();
        },
        {'sourceMemId': sourceMemId},
      );

  Future<Iterable<MemPrePostEntity>> archivePrePosts({
    int? relatedMemId,
    DateTime? archivedAt,
  }) =>
      v(
        () async {
          var query = driftDb.select(driftDb.memPrePosts);
          if (relatedMemId != null) {
            query = query
              ..where(
                (t) =>
                    t.sourceMemId.equals(relatedMemId) |
                    t.targetMemId.equals(relatedMemId),
              );
          }
          final entities =
              (await query.get()).map(MemPrePostEntity.fromTuple).toList();
          return Future.wait(
            entities.map(
              (e) => replacePrePost(
                MemPrePostEntity(
                  e.sourceMemId,
                  e.targetMemId,
                  e.minutes,
                  e.id,
                  e.createdAt,
                  e.updatedAt ?? DateTime.now(),
                  archivedAt ?? DateTime.now(),
                ),
              ),
            ),
          );
        },
        {
          'relatedMemId': relatedMemId,
          'archivedAt': archivedAt,
        },
      );

  Future<Iterable<MemPrePostEntity>> unarchivePrePosts({
    int? sourceMemId,
    int? targetMemId,
    int? relatedMemId,
  }) =>
      v(
        () async {
          var query = driftDb.select(driftDb.memPrePosts);
          if (relatedMemId != null) {
            query = query
              ..where(
                (t) =>
                    t.sourceMemId.equals(relatedMemId) |
                    t.targetMemId.equals(relatedMemId),
              );
          } else {
            if (sourceMemId != null) {
              query = query..where((t) => t.sourceMemId.equals(sourceMemId));
            }
            if (targetMemId != null) {
              query = query..where((t) => t.targetMemId.equals(targetMemId));
            }
          }
          final entities =
              (await query.get()).map(MemPrePostEntity.fromTuple).toList();
          return Future.wait(
            entities.map(
              (e) => replacePrePost(
                MemPrePostEntity(
                  e.sourceMemId,
                  e.targetMemId,
                  e.minutes,
                  e.id,
                  e.createdAt,
                  DateTime.now(),
                  null,
                ),
              ),
            ),
          );
        },
        {
          'sourceMemId': sourceMemId,
          'targetMemId': targetMemId,
          'relatedMemId': relatedMemId,
        },
      );

  Future<MemParent> receiveParent(MemParent domain) => v(
        () async {
          await _rejectParentCycle(domain.memId, domain.parentMemId);
          return _insertParent(domain);
        },
        {'domain': domain},
      );

  Future<MemParent?> shipParentByMemId(int memId) => v(
        () async {
          final row = await (driftDb.select(driftDb.memParents)
                ..where((t) => t.memId.equals(memId)))
              .getSingleOrNull();
          return row == null ? null : _memParentFrom(row);
        },
        {'memId': memId},
      );

  Future<List<MemParent>> shipChildrenByParentMemId(int parentMemId) => v(
        () async {
          final rows = await (driftDb.select(driftDb.memParents)
                ..where((t) => t.parentMemId.equals(parentMemId)))
              .get();
          return rows.map(_memParentFrom).toList();
        },
        {'parentMemId': parentMemId},
      );

  Future<Set<int>> shipParentMemIdsWithUndoneChildren() => v(
        () async {
          final parentMemId = driftDb.memParents.parentMemId;
          final rows = await (driftDb.selectOnly(driftDb.memParents)
                ..addColumns([parentMemId])
                ..join([
                  drift.innerJoin(
                    driftDb.mems,
                    driftDb.mems.id.equalsExp(driftDb.memParents.memId),
                  ),
                ])
                ..where(
                  driftDb.mems.doneAt.isNull() &
                      driftDb.mems.archivedAt.isNull(),
                ))
              .get();
          return rows.map((row) => row.read(parentMemId)!).toSet();
        },
      );

  Future<Set<int>> shipOverdueCandidateIds({required DateTime now}) => v(
        () async {
          final memId = driftDb.mems.id;
          final active = driftDb.mems.doneAt.isNull() &
              driftDb.mems.archivedAt.isNull();

          final byPeriod = await (driftDb.selectOnly(driftDb.mems)
                ..addColumns([memId])
                ..where(
                  active &
                      (driftDb.mems.notifyOn.isSmallerThanValue(now) |
                          driftDb.mems.notifyAt.isSmallerThanValue(now) |
                          driftDb.mems.endOn.isSmallerThanValue(now) |
                          driftDb.mems.endAt.isSmallerThanValue(now)),
                ))
              .get();

          final byNotification = await (driftDb.selectOnly(driftDb.mems)
                ..addColumns([memId])
                ..join([
                  drift.innerJoin(
                    driftDb.memRepeatedNotifications,
                    driftDb.memRepeatedNotifications.memId.equalsExp(memId),
                  ),
                ])
                ..where(
                  active &
                      driftDb.memRepeatedNotifications.archivedAt.isNull() &
                      driftDb.memRepeatedNotifications.type
                          .equals(MemNotificationType.afterActStarted.name)
                          .not(),
                ))
              .get();

          final byIntervalTarget = await (driftDb.selectOnly(driftDb.mems)
                ..addColumns([memId])
                ..join([
                  drift.innerJoin(
                    driftDb.targets,
                    driftDb.targets.memId.equalsExp(memId),
                  ),
                ])
                ..where(
                  active & driftDb.targets.secondsAfterLastAct.isNotNull(),
                ))
              .get();

          return {
            for (final row in byPeriod) row.read(memId)!,
            for (final row in byNotification) row.read(memId)!,
            for (final row in byIntervalTarget) row.read(memId)!,
          };
        },
        {'now': now},
      );

  // items / prepost / act 履歴は Overdue 確定に不要なので読まない
  Future<List<MemEntity>> shipOverdueMaterials(Iterable<int> ids) => v(
        () async {
          final idList = ids.toSet().toList();
          if (idList.isEmpty) return const [];

          final rows = await (driftDb.select(driftDb.mems)
                ..where((t) => t.id.isIn(idList)))
              .get();
          final notificationsByMemId =
              await _repeatedNotificationsByMemId(idList);
          final targetsByMemId = await _targetsByMemId(idList);
          final entities = [
            for (final row in rows)
              MemEntity.fromTuple(
                row,
                children: {
                  'mem_repeated_notifications': notificationsByMemId[row.id] ??
                      const <MemNotificationEntity>[],
                  'target': targetsByMemId[row.id],
                },
              ),
          ];
          return _attachLatestActs(entities);
        },
        {'ids': ids},
      );

  Future<List<MemParent>> wasteParents({int? memId}) => v(
        () async {
          var query = driftDb.delete(driftDb.memParents);
          if (memId != null) {
            query = query..where((t) => t.memId.equals(memId));
          }
          final deleted = await query.goAndReturn();
          return deleted.map(_memParentFrom).toList();
        },
        {'memId': memId},
      );

  Future<MemParent> replaceParent(MemParent domain) => v(
        () async {
          await _rejectParentCycle(domain.memId, domain.parentMemId);
          await wasteParents(memId: domain.memId);
          return _insertParent(domain);
        },
        {'domain': domain},
      );

  Future<MemParent> _insertParent(MemParent parent) async {
    final inserted = await driftDb.into(driftDb.memParents).insertReturning(
          drift_schema.MemParentsCompanion(
            memId: drift.Value(parent.memId),
            parentMemId: drift.Value(parent.parentMemId),
            createdAt: drift.Value(DateTime.now()),
          ),
        );
    return _memParentFrom(inserted);
  }

  MemParent _memParentFrom(drift_schema.MemParent row) => MemParent(
        memId: row.memId,
        parentMemId: row.parentMemId,
      );

  Future<void> _rejectParentCycle(int memId, int parentMemId) async {
    if (memId == parentMemId) {
      throw ArgumentError('mem cannot be its own parent');
    }
    var cursor = parentMemId;
    final seen = <int>{memId, parentMemId};
    while (true) {
      final parent = await shipParentByMemId(cursor);
      if (parent == null) return;
      cursor = parent.parentMemId;
      if (!seen.add(cursor)) {
        throw ArgumentError('parent cycle');
      }
    }
  }

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
    final memIds = rows.map((row) => row.id);
    final itemsByMemId = await _itemsByMemId(memIds);
    final notificationsByMemId = await _repeatedNotificationsByMemId(memIds);
    final prePostsBySourceMemId = await _prePostsBySourceMemId(memIds);
    final targetsByMemId = await _targetsByMemId(memIds);
    return [
      for (final row in rows)
        MemEntity.fromTuple(
          row,
          children: {
            'mem_items': itemsByMemId[row.id] ?? const <MemItemEntity>[],
            'mem_repeated_notifications':
                notificationsByMemId[row.id] ?? const <MemNotificationEntity>[],
            'mem_preposts':
                prePostsBySourceMemId[row.id] ?? const <MemPrePostEntity>[],
            'target': targetsByMemId[row.id],
          },
        ),
    ];
  }

  Future<Map<int, Target>> _targetsByMemId(Iterable<int> memIds) async {
    final list = memIds.toSet().toList();
    final out = <int, Target>{};
    for (var i = 0; i < list.length; i += _latestActPerMemChunkSize) {
      final end = math.min(i + _latestActPerMemChunkSize, list.length);
      final chunk = list.sublist(i, end);
      final rows = await (driftDb.select(driftDb.targets)
            ..where((t) => t.memId.isIn(chunk)))
          .get();
      for (final row in rows) {
        out.putIfAbsent(
          row.memId,
          () => TargetEntity.fromTuple(row).toDomain(),
        );
      }
    }
    return out;
  }

  Future<Map<int, List<MemItemEntity>>> _itemsByMemId(
    Iterable<int> memIds,
  ) async {
    final list = memIds.toSet().toList();
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

  Future<Map<int, List<MemNotificationEntity>>> _repeatedNotificationsByMemId(
    Iterable<int> memIds,
  ) async {
    final list = memIds.toSet().toList();
    final out = <int, List<MemNotificationEntity>>{};
    for (var i = 0; i < list.length; i += _latestActPerMemChunkSize) {
      final end = math.min(i + _latestActPerMemChunkSize, list.length);
      final chunk = list.sublist(i, end);
      final rows = await (driftDb.select(driftDb.memRepeatedNotifications)
            ..where((t) => t.memId.isIn(chunk)))
          .get();
      for (final row in rows) {
        (out[row.memId] ??= []).add(MemNotificationEntity.fromTuple(row));
      }
    }
    return out;
  }

  Future<Map<int, List<MemPrePostEntity>>> _prePostsBySourceMemId(
    Iterable<int> memIds,
  ) async {
    final list = memIds.toSet().toList();
    final out = <int, List<MemPrePostEntity>>{};
    for (var i = 0; i < list.length; i += _latestActPerMemChunkSize) {
      final end = math.min(i + _latestActPerMemChunkSize, list.length);
      final chunk = list.sublist(i, end);
      final rows = await (driftDb.select(driftDb.memPrePosts)
            ..where((t) => t.sourceMemId.isIn(chunk)))
          .get();
      for (final row in rows) {
        (out[row.sourceMemId] ??= []).add(MemPrePostEntity.fromTuple(row));
      }
    }
    return out;
  }

  Future<List<MemItemEntity>> _updateItems(
    int memId,
    List<MemItemEntity> items,
  ) {
    if (items.isEmpty) return Future.value(const []);
    return Future.wait(
      items.map((item) async {
        final updated = await (driftDb.update(driftDb.memItems)
              ..where((t) => t.id.equals(item.id)))
            .writeReturning(
          convertIntoMemItemsUpdateable(
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
        );
        return MemItemEntity.fromTuple(updated.single);
      }),
    );
  }

  Future<List<MemItemEntity>> _insertItems(int memId, List<MemItem> items) {
    if (items.isEmpty) return Future.value(const []);
    return Future.wait(
      items.map((item) async {
        final inserted = await driftDb.into(driftDb.memItems).insertReturning(
              convertIntoMemItemsInsertable(
                MemItem(memId, item.type, item.value),
                DateTime.now(),
              ),
            );
        return MemItemEntity.fromTuple(inserted);
      }),
    );
  }

  Future<List<MemEntity>> _attachLatestActs(List<MemEntity> mems) async {
    final latestByMemId = await _latestActRowsByMemId(mems.map((m) => m.id));
    final withLatest = mems.map((m) {
      final row = latestByMemId[m.id];
      if (row == null) return m;
      return m.updatedWith(
        latestAct: () => ActEntity.fromTuple(row).toDomain(),
      );
    }).toList();
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

    return mems.map((m) {
      if (m.latestAct?.isSkipped != true) return m;
      final anchor = anchorsByMemId[m.id];
      if (anchor == null) return m;
      return m.updatedWith(
        scheduleAnchorAct: () => anchor.toDomain(),
      );
    }).toList();
  }

  Future<Map<int, drift_schema.Act>> _latestActRowsByMemId(
    Iterable<int> memIds,
  ) async {
    final list = memIds.toSet().toList();
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
