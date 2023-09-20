import 'package:mem/databases/table_definitions/base.dart';

import '_entity_v2.dart';
import 'types.dart';

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
  Map<AttributeName, dynamic> toMap() => {
        defPkId.name: id,
        defColCreatedAt.name: createdAt,
        defColUpdatedAt.name: updatedAt,
        defColArchivedAt.name: archivedAt,
      };
}
