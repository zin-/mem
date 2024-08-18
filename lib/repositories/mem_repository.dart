import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/repositories/mem_entity.dart';

class MemRepository extends DatabaseTupleRepository<MemEntity, SavedMemEntity> {
  MemRepository() : super(databaseDefinition, defTableMems);

  @override
  SavedMemEntity pack(Map<String, dynamic> map) => SavedMemEntity.fromMap(map);

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
  }) =>
      v(
        () => super.ship(
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
        ),
        {
          'id': id,
          'archived': archived,
          'done': done,
          'condition': condition,
          'groupBy': groupBy,
          'orderBy': orderBy,
          'offset': offset,
          'limit': limit,
        },
      );

  @override
  Future<List<SavedMemEntity>> waste({
    int? id,
    Condition? condition,
  }) =>
      v(
        () => super.waste(
          condition: And(
            [
              if (id != null) Equals(defPkId, id),
// coverage:ignore-start
              if (condition != null) condition,
// coverage:ignore-end
            ],
          ),
        ),
        {
          'id': id,
          'condition': condition,
        },
      );
}
