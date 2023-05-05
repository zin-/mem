import 'package:mem/core/date_and_time.dart';

import 'entity_value.dart';

typedef MemId = int;

class Mem extends EntityValue {
  String name;
  DateTime? doneAt;
  DateAndTime? notifyAt;

  Mem({
    required this.name,
    this.doneAt,
    this.notifyAt,
    int? id,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? archivedAt,
  }) : super(
          id: id,
          createdAt: createdAt,
          updatedAt: updatedAt,
          archivedAt: archivedAt,
        );

  bool isDone() => doneAt != null;

  @override
  String toString() => {
        'name': name,
        'doneAt': doneAt,
        'notifyAt': notifyAt,
      }.toString();

  // FIXME エレガントじゃない
  Mem copied() => Mem(
        name: name,
        doneAt: doneAt,
        notifyAt: notifyAt,
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        archivedAt: archivedAt,
      );
}
