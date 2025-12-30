import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
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
  }) {
    final native = super.ship(
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

    return native;
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
