import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/features/mems/mem_entity.dart';

class MemRepository extends DatabaseTupleRepository<Mem, int, MemEntity> {
  @override
  Future<List<MemEntity>> shipV2({
    int? id,
    bool? archived,
    bool? done,
    Condition? condition,
    List<TableDefinition>? loadChildren,
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
        loadChildren: [],
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
