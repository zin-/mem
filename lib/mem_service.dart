import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

class MemDetail {
  final Mem mem;
  final List<MemItem> memItems;

  MemDetail(this.mem, this.memItems);

  @override
  String toString() => '{'
      ' mem: $mem'
      ', memItems: $memItems'
      ' }';
}

class MemService {
  Future<MemDetail> create(MemDetail memDetail) => t(
        {'memDetail': memDetail},
        () async {
          final receivedMem = (await MemRepository()
                  .receive(MemEntity.fromDomain(memDetail.mem)))
              .toDomain();
          final receivedMemItems = (await Future.wait(memDetail.memItems
                  .map((e) => e..memId = receivedMem.id)
                  .map((e) => MemItemRepository()
                      .receive(MemItemEntity.fromDomain(e)))))
              .map((e) => e.toDomain())
              .toList();

          return MemDetail(
            receivedMem,
            receivedMemItems,
          );
        },
      );

  Future<MemDetail> update(MemDetail memDetail) => t(
        {'memDetail': memDetail},
        () async {
          final updatedMem = (await MemRepository()
                  .update(MemEntity.fromDomain(memDetail.mem)))
              .toDomain();
          final updatedMemItems =
              (await Future.wait(memDetail.memItems.map((e) {
            final memItemEntity = MemItemEntity.fromDomain(e);
            return memItemEntity.isSaved()
                ? MemItemRepository().update(memItemEntity)
                : MemItemRepository()
                    .receive(memItemEntity..memId = updatedMem.id);
          })))
                  .map((e) => e.toDomain())
                  .toList();

          return MemDetail(updatedMem, updatedMemItems);
        },
      );

  Future<MemDetail> archive(Mem mem) => t(
        {'mem': mem},
        () async {
          final archivedMemEntity =
              await MemRepository().archive(MemEntity.fromDomain(mem));
          final archivedMemItems =
              (await MemItemRepository().archiveByMemId(archivedMemEntity.id))
                  .map((e) => e.toDomain())
                  .toList();

          return MemDetail(
            archivedMemEntity.toDomain(),
            archivedMemItems,
          );
        },
      );

  Future<MemDetail> unarchive(Mem mem) => t(
        {'mem': mem},
        () async {
          final unarchivedMemEntity =
              await MemRepository().unarchive(MemEntity.fromDomain(mem));
          final unarchivedMemItems = (await MemItemRepository()
                  .unarchiveByMemId(unarchivedMemEntity.id))
              .map((e) => e.toDomain())
              .toList();

          return MemDetail(
            unarchivedMemEntity.toDomain(),
            unarchivedMemItems,
          );
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
