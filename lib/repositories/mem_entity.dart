import 'package:mem/databases/table_definitions/mems.dart';

import 'i/_database_tuple_entity.dart';

class MemEntity extends DatabaseTupleEntity {
  final String name;
  final DateTime? doneAt;
  final DateTime? notifyOn;
  final DateTime? notifyAt;
  final DateTime? endOn;
  final DateTime? endAt;

  MemEntity.fromMap(Map<String, dynamic> valueMap)
      : name = valueMap[defColMemsName.name],
        doneAt = valueMap[defColMemsDoneAt.name],
        notifyOn = valueMap[defColMemsStartOn.name],
        notifyAt = valueMap[defColMemsStartAt.name],
        endOn = valueMap[defColMemsEndOn.name],
        endAt = valueMap[defColMemsEndAt.name],
        super.fromMap(valueMap);
}
