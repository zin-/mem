import 'package:mem/database/table_definitions/mems.dart';

import 'i/_database_tuple_entity_v2.dart';

class MemEntity extends DatabaseTupleEntity {
  final String name;
  final DateTime? doneAt;
  final DateTime? notifyOn;
  final DateTime? notifyAt;
  final DateTime? endOn;
  final DateTime? endAt;

  MemEntity(
    this.name, {
    this.doneAt,
    this.notifyOn,
    this.notifyAt,
    this.endOn,
    this.endAt,
    int? super.id,
  });

  MemEntity.fromMap(Map<String, dynamic> valueMap)
      : name = valueMap[defMemName.name],
        doneAt = valueMap[defMemDoneAt.name],
        notifyOn = valueMap[defMemStartOn.name],
        notifyAt = valueMap[defMemStartAt.name],
        endOn = valueMap[defMemEndOn.name],
        endAt = valueMap[defMemEndAt.name],
        super.fromMap(valueMap);
}
