import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';

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

MemItem minSavedMemItem(int memId, int id, {dynamic value}) =>
    minMemItem(memId, id: id)
      ..value = value
      ..createdAt = DateTime.now();
