import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/entity.dart';

mixin SavedDatabaseTuple<T> on Entity {
  late T id;
  late DateTime createdAt;
  DateTime? updatedAt;
  DateTime? archivedAt;

  void pack(Map<String, dynamic> tuple) {
    id = tuple[defPkId.name];
    createdAt = tuple[defColCreatedAt.name];
    updatedAt = tuple[defColUpdatedAt.name];
    archivedAt = tuple[defColArchivedAt.name];
  }

  Map<String, dynamic> unpack() {
    return {
      defPkId.name: id,
      defColCreatedAt.name: createdAt,
      defColUpdatedAt.name: updatedAt,
      defColArchivedAt.name: archivedAt,
    };
  }
}

abstract class DatabaseTupleEntity implements EntityV2 {
  dynamic id;
  DateTime? createdAt;
  late DateTime? updatedAt;
  late DateTime? archivedAt;

  DatabaseTupleEntity({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });

  DatabaseTupleEntity.fromMap(Map<String, dynamic> valueMap)
      : id = valueMap[defPkId.name],
        createdAt = valueMap[defColCreatedAt.name],
        updatedAt = valueMap[defColUpdatedAt.name],
        archivedAt = valueMap[defColArchivedAt.name];

  @override
  Map<String, dynamic> toMap() => {
        defPkId.name: id,
        defColCreatedAt.name: createdAt,
        defColUpdatedAt.name: updatedAt,
        defColArchivedAt.name: archivedAt,
      };
}
