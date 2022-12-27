import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

Mem minMem({int? id}) => Mem(
      name: 'mem name',
      id: id,
    );

Mem minSavedMem(int id) => minMem(id: id)
  ..name = 'saved mem name'
  ..createdAt = DateTime.now();

MemItem minMemItem(int memId, {int? id}) => MemItem(
      memId: memId,
      type: MemItemType.memo,
      value: 'memItem value',
      id: id,
    );

MemItem minSavedMemItem(int memId, int id) =>
    minMemItem(memId, id: id)..value = 'saved memItem value';

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
