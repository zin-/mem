import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

final minMemEntity = MemEntity(
  name: 'mem entity name',
  doneAt: null,
  id: null,
);

MemEntity minSavedMemEntity(int id, {DateTime? createdAt}) => minMemEntity
  ..id = id
  ..createdAt = createdAt ?? DateTime.now();

final minMemoMemItemEntity = MemItemEntity(
  memId: null,
  type: MemItemType.memo,
  value: 'memo mem item value',
);

MemItemEntity minSavedMemoMemItemEntity(
  int memId,
  int id, {
  DateTime? createdAt,
}) =>
    minMemoMemItemEntity
      ..memId = memId
      ..id = id
      ..createdAt = createdAt ?? DateTime.now();
