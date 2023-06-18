import 'package:mem/framework/database/types.dart';

import 'i/_database_tuple_entity_v2.dart';

final defMemId = DefPK(idColumnName, TypeC.integer, autoincrement: true);
final defMemName = DefC('name', TypeC.text);
final defMemDoneAt = DefC('doneAt', TypeC.datetime, notNull: false);
final defMemStartOn = DefC('notifyOn', TypeC.datetime, notNull: false);
final defMemStartAt = DefC('notifyAt', TypeC.datetime, notNull: false);
final defMemEndOn = DefC('endOn', TypeC.datetime, notNull: false);
final defMemEndAt = DefC('endAt', TypeC.datetime, notNull: false);

final memTableDefinition = DefT(
  'mems',
  [
    defMemId,
    defMemName,
    defMemDoneAt,
    defMemStartOn,
    defMemStartAt,
    defMemEndOn,
    defMemEndAt,
    ...defaultColumnDefinitions
  ],
);

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
