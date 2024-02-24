import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/repository/entity.dart';

mixin SavedDatabaseTupleMixin<T> on EntityV1 {
  late T id;
  late DateTime createdAt;
  DateTime? updatedAt;
  DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

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

  SavedDatabaseTupleMixin copiedFrom(SavedDatabaseTupleMixin origin) => this
    ..id = origin.id
    ..createdAt = origin.createdAt
    ..updatedAt = origin.updatedAt
    ..archivedAt = origin.archivedAt;

  @override
  String toString() => "${super.toString()}${unpack()}";
}
