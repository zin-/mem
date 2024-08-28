import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/repository/entity.dart';

mixin SavedDatabaseTupleMixinV1<T> on EntityV1 {
  late T id;
  late DateTime createdAt;
  DateTime? updatedAt;
  DateTime? archivedAt;

  bool get isArchived => archivedAt != null;

  Map<String, dynamic> unpack() {
    return {
      defPkId.name: id,
      defColCreatedAt.name: createdAt,
      defColUpdatedAt.name: updatedAt,
      defColArchivedAt.name: archivedAt,
    };
  }

  SavedDatabaseTupleMixinV1 copiedFrom(SavedDatabaseTupleMixinV1 origin) => this
    ..id = origin.id
    ..createdAt = origin.createdAt
    ..updatedAt = origin.updatedAt
    ..archivedAt = origin.archivedAt;

  @override
  String toString() => "${super.toString()}${unpack()}";
}

mixin DatabaseTupleEntity<PrimaryKey> on Entity {
  late PrimaryKey id;
  late DateTime createdAt;
  late DateTime? updatedAt;
  late DateTime? archivedAt;

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
