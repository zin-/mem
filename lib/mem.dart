import 'package:flutter/material.dart';

class Mem {
  final int? id;
  String name;
  DateTime? doneAt;
  DateTime? notifyOn;
  TimeOfDay? notifyAt;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? archivedAt;

  Mem({
    required this.name,
    this.doneAt,
    this.notifyOn,
    this.notifyAt,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });

  bool isArchived() => id != null && createdAt != null && archivedAt != null;

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

class MemItem {
  final int? id;
  int? memId;
  final MemItemType type;
  dynamic value;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? archivedAt;

  MemItem({
    this.id,
    this.memId,
    required this.type,
    this.value,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });
}
