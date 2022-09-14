import 'package:mem/logger.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

class MemDetail {
  final MemEntity memEntity;
  final List<MemItemEntity> memItemEntities;

  MemDetail(this.memEntity, this.memItemEntities);

  @override
  String toString() => '{'
      ' memEntity: $memEntity'
      ', memItemEntities: $memItemEntities'
      ' }';
}

class MemService {
  Future<MemDetail> create(MemDetail memDetail) => t(
        {'memDetail': memDetail},
        () async {
          final receivedMemEntity =
              await MemRepository().receive(memDetail.memEntity);
          final receivedMemItemEntities = await Future.wait(memDetail
              .memItemEntities
              .map((e) => e..memId = receivedMemEntity.id)
              .map((e) => MemItemRepository().receive(e)));

          return MemDetail(receivedMemEntity, receivedMemItemEntities);
        },
      );

  Future<MemDetail> update(MemDetail memDetail) => t(
        {'memDetail': memDetail},
        () async {
          final updatedMem = await MemRepository().update(memDetail.memEntity);
          final updatedMemItemEntities = await Future.wait(
              memDetail.memItemEntities.map((e) => e.isSaved()
                  ? MemItemRepository().update(e)
                  : MemItemRepository().receive(e..memId = updatedMem.id)));

          return MemDetail(updatedMem, updatedMemItemEntities);
        },
      );

  Future<MemDetail> archive(MemEntity memEntity) => t(
        {'memEntity': memEntity},
        () async {
          final archivedMem = await MemRepository().archive(memEntity);
          final archivedMemItems =
              await MemItemRepository().archiveByMemId(archivedMem.id);

          return MemDetail(archivedMem, archivedMemItems);
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
