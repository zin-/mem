import 'package:mem/databases/database.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/database_aceccsor/mems_dao.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/features/mems/mem_entity.dart';

class MemRepository extends DatabaseTupleRepository<MemEntity, SavedMemEntity> {
  @override
  SavedMemEntity pack(Map<String, dynamic> map) => SavedMemEntity(map);

  @override
  Future<List<SavedMemEntity>> ship({
    int? id,
    bool? archived,
    bool? done,
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) async {
    // TODO 新しいのと古いのを比較して同じになるんだったら古い方を削除する
    //   保存の処理を先に行わないと比較ができない
    final newMems = await MemsDao(AppDatabase()).getMems();
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

  static MemRepository? _instance;
  factory MemRepository({MemRepository? mock}) =>
      _instance ??= mock ?? MemRepository._();
  MemRepository._() : super(databaseDefinition, defTableMems);
}
