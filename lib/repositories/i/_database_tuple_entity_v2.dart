import 'package:mem/database/i/types.dart';

import '_entity_v2.dart';
import 'types.dart';

const AttributeName idColumnName = 'id';
const AttributeName createdAtColumnName = 'createdAt';
const AttributeName updatedAtColumnName = 'updatedAt';
const AttributeName archivedAtColumnName = 'archivedAt';

final defaultColumnDefinitions = [
  DefC(createdAtColumnName, TypeC.datetime),
  DefC(updatedAtColumnName, TypeC.datetime, notNull: false),
  DefC(archivedAtColumnName, TypeC.datetime, notNull: false),
];

abstract class DatabaseTupleEntityV2 implements EntityV2 {
  dynamic id;
  DateTime? createdAt;
  late DateTime? updatedAt;
  late DateTime? archivedAt;

  DatabaseTupleEntityV2({
    required this.id,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });

  DatabaseTupleEntityV2.fromMap(Map<String, dynamic> valueMap)
      : id = valueMap[idColumnName],
        createdAt = valueMap[createdAtColumnName],
        updatedAt = valueMap[updatedAtColumnName],
        archivedAt = valueMap[archivedAtColumnName];

  Map<AttributeName, dynamic> toMap() => {
        idColumnName: id,
        createdAtColumnName: createdAt,
        updatedAtColumnName: updatedAt,
        archivedAtColumnName: archivedAt,
      };
}
