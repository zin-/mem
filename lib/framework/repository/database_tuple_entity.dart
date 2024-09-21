import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/repository/entity.dart';

mixin DatabaseTupleEntity<PrimaryKey> on Entity {
  late PrimaryKey id;
  late DateTime createdAt;
  late DateTime? updatedAt;
  late DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  DatabaseTupleEntity<PrimaryKey> withMap(Map<String, dynamic> map) {
    id = map[defPkId.name];
    createdAt = map[defColCreatedAt.name];
    updatedAt = map[defColUpdatedAt.name];
    archivedAt = map[defColArchivedAt.name];
    return this;
  }

  @override
  Map<String, dynamic> get toMap => super.toMap
    ..addAll({
      defPkId.name: id,
      defColCreatedAt.name: createdAt,
      defColUpdatedAt.name: updatedAt,
      defColArchivedAt.name: archivedAt,
    });
}
