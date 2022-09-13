import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

class MemService {
  Future<MemEntity> create(
          Map<String, dynamic> memMap, List<MemItemEntity> memItems) =>
      t(
        {'memMap': memMap, 'memItems': memItems},
        () async {
          final receivedMem = await MemRepository().receive(memMap);
          for (var memItem in memItems) {
            await MemItemRepository().receive({
              memIdColumnName: receivedMem.id,
              memDetailTypeColumnName: memItem.type.name,
              memDetailValueColumnName: memItem.value,
            });
          }

          return receivedMem;
        },
      );

  Future<MemEntity> update(MemEntity memEntity, List<MemItemEntity> memItems) =>
      t(
        {'memEntity': memEntity, 'memItems': memItems},
        () async {
          final receivedMem = await MemRepository().update(memEntity);
          for (var memItem in memItems) {
            await MemItemRepository().update(memItem);
          }

          return receivedMem;
        },
      );

  Future<MemEntity> archive(MemEntity memEntity) => t(
        {'memEntity': memEntity},
        () async {
          final receivedMem = await MemRepository().archive(memEntity);
          await MemItemRepository().archiveByMemId(receivedMem.id);

          return receivedMem;
        },
      );

  Future<MemEntity> unarchive(MemEntity memEntity) => t(
        {'memEntity': memEntity},
        () async {
          final receivedMem = await MemRepository().unarchive(memEntity);
          await MemItemRepository().unarchiveByMemId(receivedMem.id);

          return receivedMem;
        },
      );

  Future<bool> remove(int memId) => t(
        {'memId': memId},
        () async {
          await MemItemRepository().discardByMemId(memId);
          final removeResult = await MemRepository().discardById(memId);

          return removeResult;
        },
      );
}
