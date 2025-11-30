import 'package:drift/drift.dart';
import 'package:mem/databases/database.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/database_aceccsor/mems_dao.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/group_by.dart' as old;
import 'package:mem/framework/repository/order_by.dart' as old;
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/features/mems/mem_entity.dart';

class MemRepository extends DatabaseTupleRepository<MemEntity, SavedMemEntity> {
  final MemsDao _memsDao = MemsDao(AppDatabase());

  @override
  SavedMemEntity pack(Map<String, dynamic> map) => SavedMemEntity(map);

  @override
  Future<List<SavedMemEntity>> ship({
    int? id,
    bool? archived,
    bool? done,
    Condition? condition,
    old.GroupBy? groupBy,
    List<old.OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) async {
    // TODO 新しいのと古いのを比較して同じになるんだったら古い方を削除する
    //   保存の処理を先に行わないと比較ができない
    final newMems = await _memsDao.getMems();
    warn(newMems);
    final converted = newMems.map((e) {
      // return e;
      // return SavedMemEntity(e.toJson());
      return SavedMemEntity({
        defPkId.name: e.id,
        defColMemsName.name: e.name,
        defColMemsDoneAt.name: e.doneAt,
        defColMemsStartOn.name: e.notifyOn,
        defColMemsStartAt.name: e.notifyAt,
        defColMemsEndOn.name: e.endOn,
        defColMemsEndAt.name: e.endAt,
        defColCreatedAt.name: e.createdAt,
        defColUpdatedAt.name: e.updatedAt,
        defColArchivedAt.name: e.archivedAt,
      });
    }).toList();
    warn(converted);

    final oldMems = await super.ship(
      condition: And(
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
          if (condition != null) condition,
        ],
      ),
      groupBy: groupBy,
      orderBy: orderBy,
      offset: offset,
      limit: limit,
    );

    return oldMems;
  }

  @override
  Future<List<SavedMemEntity>> waste({
    int? id,
    Condition? condition,
  }) =>
      super.waste(
        condition: And(
          [
            if (id != null) Equals(defPkId, id),
// coverage:ignore-start
            if (condition != null) condition,
// coverage:ignore-end
          ],
        ),
      );

  @override
  Future<SavedMemEntity> receive(
    MemEntity entity, {
    DateTime? createdAt,
  }) async {
    final newId = await _memsDao.insert(MemsCompanion(
      name: Value(entity.value.name),
      doneAt: Value(entity.value.doneAt),
      notifyOn: Value(entity.value.period?.start),
      notifyAt: Value(entity.value.period?.start?.isAllDay == true
          ? null
          : entity.value.period?.start),
      endOn: Value(entity.value.period?.end),
      endAt: Value(entity.value.period?.end?.isAllDay == true
          ? null
          : entity.value.period?.end),
      createdAt: Value(createdAt ?? DateTime.now()),
    ));
    final newSavedMem = SavedMemEntity({
      defPkId.name: newId,
      defColMemsName.name: entity.value.name,
      defColMemsDoneAt.name: entity.value.doneAt,
      defColMemsStartOn.name: entity.value.period?.start,
      defColMemsStartAt.name: entity.value.period?.start?.isAllDay == true
          ? null
          : entity.value.period?.start,
      defColMemsEndOn.name: entity.value.period?.end,
      defColMemsEndAt.name: entity.value.period?.end?.isAllDay == true
          ? null
          : entity.value.period?.end,
      defColCreatedAt.name: createdAt ?? DateTime.now(),
      defColUpdatedAt.name: null,
      defColArchivedAt.name: null,
    });
    warn(newSavedMem);
    final oldSavedMem = await super.receive(entity);

    // TODO check
    if (newSavedMem.toMap.toString() != oldSavedMem.toMap.toString()) {
      // createdAtが微妙に異なるけどそれ以外は一緒っぽい
      warn('newSavedMem: ${newSavedMem.toMap.toString()}');
      warn('oldSavedMem: ${oldSavedMem.toMap.toString()}');
    }
    return oldSavedMem;
  }

  static MemRepository? _instance;
  factory MemRepository({MemRepository? mock}) =>
      _instance ??= mock ?? MemRepository._();
  MemRepository._() : super(databaseDefinition, defTableMems);
}
