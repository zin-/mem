import 'package:mem/database/tables/base.dart';

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
      : id = valueMap[idPKDef.name],
        createdAt = valueMap[createdAtColDef.name],
        updatedAt = valueMap[updatedAtColDef.name],
        archivedAt = valueMap[archivedAtColDef.name];

  @override
  Map<AttributeName, dynamic> toMap() => {
        idPKDef.name: id,
        createdAtColDef.name: createdAt,
        updatedAtColDef.name: updatedAt,
        archivedAtColDef.name: archivedAt,
      };
}
