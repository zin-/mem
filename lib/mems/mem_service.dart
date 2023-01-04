import 'package:flutter/material.dart';
import 'package:mem/core/date_and_time.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/notifications/notification_repository.dart';
import 'package:mem/repositories/mem_item_repository.dart';
import 'package:mem/repositories/mem_repository.dart';
import 'package:mem/notifications/notification_service.dart';

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
  final MemRepositoryV2 _memRepositoryV2;
  final MemItemRepository _memItemRepository;
  final NotificationService _notificationService;

  MemService._(
    this._memRepository,
    this._memRepositoryV2,
    this._memItemRepository,
    this._notificationService,
  );

  static MemService? _instance;

  factory MemService({
    MemRepository? memRepository,
    MemRepositoryV2? memRepositoryV2,
    MemItemRepository? memItemRepository,
    NotificationService? notificationService,
  }) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = MemService._(
        memRepository ?? MemRepository(),
        memRepositoryV2 ?? MemRepositoryV2(),
        memItemRepository ?? MemItemRepository(),
        notificationService ?? NotificationService(),
      );
      _instance = tmp;
    }
    return tmp;
  }

  Future<MemDetail> save(MemDetail memDetail, {bool undo = false}) => t(
        {'memDetail': memDetail},
        () async {
          Mem savedMem;
          if (memDetail.mem.isSaved() && !undo) {
            savedMem = await _memRepositoryV2.replace(memDetail.mem);
          } else {
            savedMem = await _memRepositoryV2.receive(memDetail.mem);
          }

          final savedMemItems = (await Future.wait(memDetail.memItems.map((e) =>
                  (e.isSaved() && !undo
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

  Future<MemDetail> doneByMemId(int memId) => t(
        {'memId': memId},
        () async => save(MemDetail(
          (await fetchMemById(memId))..doneAt = DateTime.now(),
          [],
        )),
      );

  Future<MemDetail> undoneByMemId(int memId) => t(
        {'memId': memId},
        () async => save(MemDetail(
          (await fetchMemById(memId))..doneAt = null,
          [],
        )),
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
        () => _memRepositoryV2.shipByCondition(
          showNotArchived == showArchived ? null : showArchived,
          showNotDone == showDone ? null : showDone,
        ),
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
          final archivedMem = await _memRepositoryV2.archive(mem);
          final archivedMemItems =
              (await _memItemRepository.archiveByMemId(archivedMem.id))
                  .map((e) => convertMemItemFromEntity(e))
                  .toList();

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
          final unarchivedMem = await _memRepositoryV2.unarchive(mem);
          final unarchivedMemItems =
              (await _memItemRepository.unarchiveByMemId(unarchivedMem.id))
                  .map((e) => convertMemItemFromEntity(e))
                  .toList();

          _notificationService.memReminder(unarchivedMem);

          return MemDetail(
            unarchivedMem,
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

  // FIXME convert系は別のクラスに分割する
  // できれば自動生成したい
  Mem convertMemFromEntity(MemEntity memEntity) => v(
        {'memEntity': memEntity},
        () {
          final notifyOn = memEntity.notifyOn;

          return Mem(
            name: memEntity.name,
            doneAt: memEntity.doneAt,
            notifyOn: memEntity.notifyOn,
            notifyAt: memEntity.notifyAt == null
                ? null
                : TimeOfDay.fromDateTime(memEntity.notifyAt!),
            notifyAtV2: notifyOn == null
                ? null
                : DateAndTime(
                    notifyOn.year,
                    notifyOn.month,
                    notifyOn.day,
                    memEntity.notifyAt?.hour,
                    memEntity.notifyAt?.minute,
                  ),
            id: memEntity.id,
            createdAt: memEntity.createdAt,
            updatedAt: memEntity.updatedAt,
            archivedAt: memEntity.archivedAt,
          );
        },
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
