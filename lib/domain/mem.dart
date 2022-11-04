import 'package:flutter/material.dart';
import 'package:mem/domain/entity_value.dart';

class Mem extends EntityValue {
  String name;
  DateTime? doneAt;
  DateTime? notifyOn;
  TimeOfDay? notifyAt;

  Mem({
    required this.name,
    this.doneAt,
    this.notifyOn,
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
        'notifyOn': notifyOn,
        'notifyAt': notifyAt,
      }.toString();

  // FIXME エレガントじゃない
  Mem copied() => Mem(
        name: name,
        doneAt: doneAt,
        notifyOn: notifyOn,
        notifyAt: notifyAt,
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
