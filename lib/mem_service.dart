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
