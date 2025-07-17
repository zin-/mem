import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/repository/entity.dart';

mixin DatabaseTupleEntityV2<PRIMARY_KEY, T> on Entity<T> {
  late PRIMARY_KEY id;
  late DateTime createdAt;
  late DateTime? updatedAt;
  late DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  void withMap(Map<String, Object?> map) {
    id = map[defPkId.name] as PRIMARY_KEY;
    createdAt = map[defColCreatedAt.name] as DateTime;
    updatedAt = map[defColUpdatedAt.name] as DateTime?;
    archivedAt = map[defColArchivedAt.name] as DateTime?;
  }

  @override
  Map<String, Object?> get toMap => super.toMap
    ..addAll({
      defPkId.name: id,
      defColCreatedAt.name: createdAt,
      defColUpdatedAt.name: updatedAt,
      defColArchivedAt.name: archivedAt,
    });
}

final Map<Type, TableDefinition> entityTableRelations = {};
