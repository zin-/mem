import 'package:mem/core/mem_item.dart';
import 'package:mem/repositories/i/_database_tuple_entity_v2.dart';

class MemItemEntityV2 extends DatabaseTupleEntityV2 {
  int? memId;
  MemItemType type;
  dynamic value;

  MemItemEntityV2({
    required this.memId,
    required this.type,
    this.value,
    super.id,
    super.createdAt,
    super.updatedAt,
    super.archivedAt,
  });
}
