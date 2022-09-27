import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

class MemDetail {
  final Mem mem;
  final List<MemItemEntity> memItemEntities;

  MemDetail(this.mem, this.memItemEntities);

  @override
  String toString() => '{'
      ' mem: $mem'
      ', memItemEntities: $memItemEntities'
      ' }';
}

class MemService {
  Future<MemDetail> create(MemDetail memDetail) => t(
        {'memDetail': memDetail},
        () async {
          final receivedMemEntity = await MemRepository()
              .receive(MemEntity.fromDomain(memDetail.mem));
          final receivedMemItemEntities = await Future.wait(memDetail
              .memItemEntities
              .map((e) => e..memId = receivedMemEntity.id)
              .map((e) => MemItemRepository().receive(e)));

          return MemDetail(
            receivedMemEntity.toDomain(),
            receivedMemItemEntities,
          );
        },
      );

  Future<MemDetail> update(MemDetail memDetail) => t(
        {'memDetail': memDetail},
        () async {
          final updatedMem =
              await MemRepository().update(MemEntity.fromDomain(memDetail.mem));
          final updatedMemItemEntities = await Future.wait(
              memDetail.memItemEntities.map((e) => e.isSaved()
                  ? MemItemRepository().update(e)
                  : MemItemRepository().receive(e..memId = updatedMem.id)));

          return MemDetail(updatedMem.toDomain(), updatedMemItemEntities);
        },
      );

  Future<MemDetail> archive(MemEntity memEntity) => t(
        {'memEntity': memEntity},
        () async {
          final archivedMem = await MemRepository().archive(memEntity);
          final archivedMemItems =
              await MemItemRepository().archiveByMemId(archivedMem.id);

          return MemDetail(archivedMem.toDomain(), archivedMemItems);
        },
      );

  Future<MemDetail> unarchive(MemEntity memEntity) => t(
        {'memEntity': memEntity},
        () async {
          final unarchivedMem = await MemRepository().unarchive(memEntity);
          final unarchivedMemItems =
              await MemItemRepository().unarchiveByMemId(unarchivedMem.id);

          return MemDetail(unarchivedMem.toDomain(), unarchivedMemItems);
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
