import 'package:mem/databases/child_fk_cascade.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/drift_repository.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/load_child_spec.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/framework/singleton.dart';
import 'package:mem/features/logger/log_service.dart';

class MemRepository extends DriftRepository {
  static List<LoadChildSpec> get loadLatestActChild => [
        LoadChildSpec(
          table: defTableActs,
          resultKey: 'latest_act',
          orderBy: [
            DescendingCoalesce(defColActsStart, defColCreatedAt),
            Descending(defPkId),
          ],
          limit: 1,
        ),
      ];

  Future<List<MemEntity>> ship({
    int? id,
    bool? archived,
    bool? done,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
    List<LoadChildSpec>? loadChildren,
  }) =>
      v(
        () async {
          if (_usesAccessorShip(
            groupBy: groupBy,
            orderBy: orderBy,
            loadChildren: loadChildren,
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
              loadChildren: loadChildren,
            );
            return List<MemEntity>.from(rows);
          }

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
          return rows.map(MemEntity.fromTuple).toList();
        },
        {
          'id': id,
          'archived': archived,
          'done': done,
          'groupBy': groupBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
          'loadChildren': loadChildren,
        },
      );

  Future<MemEntity> shipById(
    int id, {
    List<LoadChildSpec>? loadChildren,
  }) =>
      v(
        () async {
          final rows = await ship(
            id: id,
            loadChildren: loadChildren,
          );
          return rows.single;
        },
        {'id': id, 'loadChildren': loadChildren},
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
    List<LoadChildSpec>? loadChildren,
  }) =>
      loadChildren != null && loadChildren.isNotEmpty ||
      groupBy != null ||
      (orderBy != null && orderBy.isNotEmpty);

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

  MemRepository._();

  factory MemRepository({MemRepository? mock}) {
    if (mock != null) {
      Singleton.override<MemRepository>(mock);
      return mock;
    }
    return Singleton.of(() => MemRepository._());
  }
}
