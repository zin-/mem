import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/repository/load_child_spec.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';
import 'package:mem/features/mems/mem_entity.dart';

class MemRepository extends DatabaseTupleRepository<Mem, int, MemEntity> {
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

  @override
  Future<List<MemEntity>> shipV2({
    int? id,
    bool? archived,
    bool? done,
    Condition? condition,
    GroupBy? groupBy,
    List<OrderBy>? orderBy,
    int? offset,
    int? limit,
    List<LoadChildSpec>? loadChildren,
  }) =>
      super.shipV2(
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
        loadChildren: loadChildren,
      );

  @override
  Future<List<MemEntity>> wasteV2({
    int? id,
    Condition? condition,
  }) =>
      super.wasteV2(
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
