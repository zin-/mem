import 'package:flutter/material.dart';
import 'package:mem/logger.dart';
import 'package:mem/domains/mem.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/repositories/notification_repository.dart';
import 'package:mem/services/notification_service.dart';

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
  final MemRepository _memRepository;
  final MemItemRepository _memItemRepository;
  final NotificationService _notificationService;

  MemService._(
    this._memRepository,
    this._memItemRepository,
    this._notificationService,
  );

  static MemService? _instance;

  factory MemService({
    MemRepository? memRepository,
    MemItemRepository? memItemRepository,
    NotificationService? notificationService,
  }) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = MemService._(
        memRepository ?? MemRepository(),
        memItemRepository ?? MemItemRepository(),
        notificationService ?? NotificationService(),
      );
      _instance = tmp;
    }
    return tmp;
  }

  Future<MemDetail> save(MemDetail memDetail) => t(
        {'memDetail': memDetail},
        () async {
          final savedMem = convertMemFromEntity(await (memDetail.mem.isSaved()
                  ? _memRepository.update
                  : _memRepository.receive)
              .call(convertMemIntoEntity(memDetail.mem)));

          final savedMemItems = (await Future.wait(memDetail.memItems.map((e) =>
                  (e.isSaved()
                          ? _memItemRepository.update
                          : _memItemRepository.receive)
                      .call(convertMemItemIntoEntity(e)..memId = savedMem.id))))
              .map((e) => convertMemItemFromEntity(e))
              .toList();

          _notificationService.memReminder(savedMem);

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
          final memEntities = (await _memRepository.ship(
            archive: showNotArchived == showArchived ? null : showArchived,
            done: showNotDone == showDone ? null : showDone,
          ));

          return memEntities.map((e) => convertMemFromEntity(e)).toList();
        },
      );

  Future<Mem> fetchMemById(int memId) => t(
        {'memId': memId},
        () async {
          final memEntity = await _memRepository.shipById(memId);

          return convertMemFromEntity(memEntity);
        },
      );

  Future<List<MemItem>> fetchMemItemsByMemId(int memId) => t(
        {'memId': memId},
        () async {
          final memItemEntities = await _memItemRepository.shipByMemId(memId);

          return memItemEntities
              .map((e) => convertMemItemFromEntity(e))
              .toList();
        },
      );

  Future<MemDetail> archive(Mem mem) => t(
        {'mem': mem},
        () async {
          final archivedMemEntity =
              await _memRepository.archive(convertMemIntoEntity(mem));
          final archivedMemItems =
              (await _memItemRepository.archiveByMemId(archivedMemEntity.id))
                  .map((e) => convertMemItemFromEntity(e))
                  .toList();

          final archivedMem = convertMemFromEntity(archivedMemEntity);
          _notificationService.memReminder(archivedMem);

          return MemDetail(
            archivedMem,
            archivedMemItems,
          );
        },
      );

  Future<MemDetail> unarchive(Mem mem) => t(
        {'mem': mem},
        () async {
          final unarchivedMemEntity =
              await _memRepository.unarchive(convertMemIntoEntity(mem));
          final unarchivedMemItems = (await _memItemRepository
                  .unarchiveByMemId(unarchivedMemEntity.id))
              .map((e) => convertMemItemFromEntity(e))
              .toList();

          final unarchivedMem = convertMemFromEntity(unarchivedMemEntity);
          _notificationService.memReminder(unarchivedMem);

          return MemDetail(
            convertMemFromEntity(unarchivedMemEntity),
            unarchivedMemItems,
          );
        },
      );

  Future<bool> remove(int memId) => t(
        {'memId': memId},
        () async {
          await _memItemRepository.discardByMemId(memId);
          final removeResult = await _memRepository.discardById(memId);

          // FIXME 関数内でMemを保持していないためRepositoryを参照している
          // discardされた時点でMemは存在しなくなるため、どちらにせよ無理筋かも
          NotificationRepository().discard(memId);

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

  static void reset(MemService? memService) {
    _instance = memService;
  }
}