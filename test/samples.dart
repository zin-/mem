import 'package:mem/mem.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

MemEntity minMemEntity() => MemEntity(
      name: 'mem entity name',
      doneAt: null,
      id: null,
    );

MemEntity minSavedMemEntity(int id, {DateTime? createdAt}) => minMemEntity()
  ..id = id
  ..createdAt = createdAt ?? DateTime.now();

MemItemEntity minMemoMemItemEntity() => MemItemEntity(
      memId: null,
      type: MemItemType.memo,
      value: 'memo mem item value',
    );

MemItemEntity minSavedMemoMemItemEntity(
  int memId,
  int id, {
  DateTime? createdAt,
}) =>
    minMemoMemItemEntity()
      ..memId = memId
      ..id = id
      ..createdAt = createdAt ?? DateTime.now();
