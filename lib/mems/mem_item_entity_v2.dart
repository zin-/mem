import 'package:mem/core/mem_item.dart';
import 'package:mem/repositories/i/_database_tuple_entity_v2.dart';

class MemItemEntity extends DatabaseTupleEntity {
  int? memId;
  MemItemType type;
  dynamic value;

  MemItemEntity({
    required this.memId,
    required this.type,
    this.value,
    super.id,
    super.createdAt,
    super.updatedAt,
    super.archivedAt,
  });
}
