import 'package:mem/database/i/types.dart';

import 'i/_database_tuple_entity_v2.dart';

final defMemId = DefPK(idColumnName, TypeC.integer, autoincrement: true);
final defMemName = DefC('name', TypeC.text);
final defMemDoneAt = DefC('doneAt', TypeC.datetime, notNull: false);
final defMemNotifyOn = DefC('notifyOn', TypeC.datetime, notNull: false);
final defMemNotifyAt = DefC('notifyAt', TypeC.datetime, notNull: false);

final memTableDefinition = DefT(
  'mems',
  [
    defMemId,
    defMemName,
    defMemDoneAt,
    defMemNotifyOn,
    defMemNotifyAt,
    ...defaultColumnDefinitions
  ],
);

class MemEntity extends DatabaseTupleEntity {
  final String name;
  final DateTime? doneAt;
  final DateTime? notifyOn;
  final DateTime? notifyAt;

  MemEntity(
    this.name, {
    this.doneAt,
    this.notifyOn,
    this.notifyAt,
    int? super.id,
  });

  MemEntity.fromMap(Map<String, dynamic> valueMap)
      : name = valueMap[defMemName.name],
        doneAt = valueMap[defMemDoneAt.name],
        notifyOn = valueMap[defMemNotifyOn.name],
        notifyAt = valueMap[defMemNotifyAt.name],
        super.fromMap(valueMap);
}
