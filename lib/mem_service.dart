import 'package:flutter/material.dart';
import 'package:mem/logger.dart';
import 'package:mem/mem.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/repositories/notification_repository.dart';

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
  Future<MemDetail> save(MemDetail memDetail) => t(
        {'memDetail': memDetail},
        () async {
          final savedMem = convertMemFromEntity(await (memDetail.mem.isSaved()
                  ? MemRepository().update
                  : MemRepository().receive)
              .call(convertMemIntoEntity(memDetail.mem)));

          final savedMemItems = (await Future.wait(memDetail.memItems.map((e) =>
                  (e.isSaved()
                          ? MemItemRepository().update
                          : MemItemRepository().receive)
                      .call(convertMemItemIntoEntity(e)..memId = savedMem.id))))
              .map((e) => convertMemItemFromEntity(e))
              .toList();

          final notifyAt = savedMem.notifyOn?.add(Duration(
            hours: savedMem.notifyAt?.hour ?? 5,
            minutes: savedMem.notifyAt?.minute ?? 0,
          ));

          if (notifyAt != null && notifyAt.isAfter(DateTime.now())) {
            NotificationRepository().receive(
              savedMem.id,
              savedMem.name,
              notifyAt,
            );
          }

          return MemDetail(
            savedMem,
            savedMemItems,
          );
        },
      );

  Future<List<Mem>> fetchMems(
    bool showNotArchived,
    bool showArchived,
    bool showNotDone,
    bool showDone,
  ) =>
      t(
        {
          'showNotArchived': showNotArchived,
          'showArchived': showArchived,
          'showNotDone': showNotDone,
          'showDone': showDone,
        },
        () async {
          final memEntities = (await MemRepository().ship(
            archive: showNotArchived == showArchived ? null : showArchived,
            done: showNotDone == showDone ? null : showDone,
          ));

          return memEntities.map((e) => convertMemFromEntity(e)).toList();
        },
      );

  Future<Mem> fetchMemById(int memId) => t(
        {'memId': memId},
        () async {
          final memEntity = await MemRepository().shipById(memId);

          return convertMemFromEntity(memEntity);
        },
      );

  Future<List<MemItem>> fetchMemItemsByMemId(int memId) => t(
        {'memId': memId},
        () async {
          final memItemEntities = await MemItemRepository().shipByMemId(memId);

          return memItemEntities
              .map((e) => convertMemItemFromEntity(e))
              .toList();
        },
      );

  Future<MemDetail> archive(Mem mem) => t(
        {'mem': mem},
        () async {
          final archivedMemEntity =
              await MemRepository().archive(convertMemIntoEntity(mem));
          final archivedMemItems =
              (await MemItemRepository().archiveByMemId(archivedMemEntity.id))
                  .map((e) => convertMemItemFromEntity(e))
                  .toList();

          return MemDetail(
            convertMemFromEntity(archivedMemEntity),
            archivedMemItems,
          );
        },
      );

  Future<MemDetail> unarchive(Mem mem) => t(
        {'mem': mem},
        () async {
          final unarchivedMemEntity =
              await MemRepository().unarchive(convertMemIntoEntity(mem));
          final unarchivedMemItems = (await MemItemRepository()
                  .unarchiveByMemId(unarchivedMemEntity.id))
              .map((e) => convertMemItemFromEntity(e))
              .toList();

          return MemDetail(
            convertMemFromEntity(unarchivedMemEntity),
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

  Mem convertMemFromEntity(MemEntity memEntity) => v(
        {'memEntity': memEntity},
        () => Mem(
          name: memEntity.name,
          doneAt: memEntity.doneAt,
          notifyOn: memEntity.notifyOn,
          notifyAt: memEntity.notifyAt == null
              ? null
              : TimeOfDay.fromDateTime(memEntity.notifyAt!),
          id: memEntity.id,
          createdAt: memEntity.createdAt,
          updatedAt: memEntity.updatedAt,
          archivedAt: memEntity.archivedAt,
        ),
      );

  MemEntity convertMemIntoEntity(Mem mem) => v(
        {'mem': mem},
        () => MemEntity(
          name: mem.name,
          doneAt: mem.doneAt,
          notifyOn: mem.notifyOn,
          notifyAt: mem.notifyAt == null
              ? null
              : mem.notifyOn?.add(Duration(
                  hours: mem.notifyAt!.hour,
                  minutes: mem.notifyAt!.minute,
                )),
          id: mem.id,
          createdAt: mem.createdAt,
          updatedAt: mem.updatedAt,
          archivedAt: mem.archivedAt,
        ),
      );

  MemItem convertMemItemFromEntity(MemItemEntity memItemEntity) => v(
        {'memItemEntity': memItemEntity},
        () => MemItem(
          memId: memItemEntity.memId,
          type: memItemEntity.type,
          value: memItemEntity.value,
          id: memItemEntity.id,
          createdAt: memItemEntity.createdAt,
          updatedAt: memItemEntity.updatedAt,
          archivedAt: memItemEntity.archivedAt,
        ),
      );

  MemItemEntity convertMemItemIntoEntity(MemItem memItem) => v(
        {'memItem': memItem},
        () => MemItemEntity(
          memId: memItem.memId,
          type: memItem.type,
          value: memItem.value,
          id: memItem.id,
          createdAt: memItem.createdAt,
          updatedAt: memItem.updatedAt,
          archivedAt: memItem.archivedAt,
        ),
      );
}
