import 'package:flutter/material.dart';
import 'package:mem/core/date_and_time.dart';

import 'entity_value.dart';

typedef MemId = int;

class Mem extends EntityValue {
  String name;
  DateTime? doneAt;
  @Deprecated('use notifyAtV2')
  DateTime? notifyOn;
  @Deprecated('use notifyAtV2')
  TimeOfDay? notifyAt;
  DateAndTime? notifyAtV2;

  Mem({
    required this.name,
    this.doneAt,
    this.notifyOn,
    this.notifyAt,
    this.notifyAtV2,
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
        'notifyOn': notifyOn,
        'notifyAt': notifyAt,
        'notifyAtV2': notifyAtV2,
      }.toString();

  // FIXME エレガントじゃない
  Mem copied() => Mem(
        name: name,
        doneAt: doneAt,
        notifyOn: notifyOn,
        notifyAt: notifyAt,
        notifyAtV2: notifyAtV2,
        id: id,
        createdAt: createdAt,
        updatedAt: updatedAt,
        archivedAt: archivedAt,
      );
}

enum MemItemType {
  memo,
}

class MemItem extends EntityValue {
  int? memId;
  final MemItemType type;
  dynamic value;

  MemItem({
    this.memId,
    required this.type,
    this.value,
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

  @override
  String toString() => {
        'memId': memId,
        'MemItemType': MemItemType,
        'value': value,
      }.toString();
}
