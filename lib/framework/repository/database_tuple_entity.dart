import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/repository/entity.dart';

mixin SavedDatabaseTupleMixin<T> on Entity {
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
