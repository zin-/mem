import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/features/mems/mem_entity.dart';

class MemRepositoryV2
    extends DatabaseTupleRepository<MemEntityV2, SavedMemEntityV2> {
  MemRepositoryV2() : super(databaseDefinition, defTableMems);

  @override
  SavedMemEntityV2 pack(Map<String, dynamic> map) => SavedMemEntityV2(map);

  @override
  Future<List<SavedMemEntityV2>> ship({
    int? id,
    bool? archived,
    bool? done,
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
  }) =>
      super.ship(
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

  @override
  Future<List<SavedMemEntityV2>> waste({
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
}
