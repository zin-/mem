import 'package:flutter/material.dart';

class Mem {
  String name;
  DateTime? doneAt;
  DateTime? notifyOn;
  TimeOfDay? notifyAt;
  final int? id;
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

  @override
  String toString() => {
        'name': name,
        'doneAt': doneAt,
        'notifyOn': notifyOn,
        'notifyAt': notifyAt,
        'id': id,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'archivedAt': archivedAt,
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

class MemItem {
  int? memId;
  final MemItemType type;
  dynamic value;
  final int? id;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? archivedAt;

  MemItem({
    this.memId,
    required this.type,
    this.value,
    this.id,
    this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });

  @override
  String toString() => {
        'memId': memId,
        'MemItemType': MemItemType,
        'value': value,
        'id': id,
        'createdAt': createdAt,
        'updatedAt': updatedAt,
        'archivedAt': archivedAt,
      }.toString();
}
