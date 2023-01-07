import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/mems/mem_item_repository_v2.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/notifications/notification_repository.dart';
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
  final MemRepositoryV2 _memRepositoryV2;
  final MemItemRepositoryV2 _memItemRepositoryV2;
  final NotificationService _notificationService;

  MemService._(
    this._memRepositoryV2,
    this._memItemRepositoryV2,
    this._notificationService,
  );

  static MemService? _instance;

  factory MemService({
    MemRepositoryV2? memRepositoryV2,
    MemItemRepositoryV2? memItemRepositoryV2,
    NotificationService? notificationService,
  }) {
    var tmp = _instance;
    if (tmp == null) {
      tmp = MemService._(
        memRepositoryV2 ?? MemRepositoryV2(),
        memItemRepositoryV2 ?? MemItemRepositoryV2(),
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
                          ? _memItemRepositoryV2.replace
                          : _memItemRepositoryV2.receive)
                      .call(e..memId = savedMem.id))))
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
        () => _memRepositoryV2.shipById(memId),
      );

  Future<List<MemItem>> fetchMemItemsByMemId(int memId) => t(
        {'memId': memId},
        () async => (await _memItemRepositoryV2.shipByMemId(memId)).toList(),
      );

  Future<MemDetail> archive(Mem mem) => t(
        {'mem': mem},
        () async {
          final archivedMem = await _memRepositoryV2.archive(mem);
          final archivedMemItems =
              (await _memItemRepositoryV2.archiveByMemId(archivedMem.id))
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
              (await _memItemRepositoryV2.unarchiveByMemId(unarchivedMem.id))
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
          await _memItemRepositoryV2.wasteByMemId(memId);
          await _memRepositoryV2.wasteById(memId);

          // FIXME 関数内でMemを保持していないためRepositoryを参照している
          // discardされた時点でMemは存在しなくなるため、どちらにせよ無理筋かも
          NotificationRepository().discard(memId);

          return true;
        },
      );

  static void reset(MemService? memService) {
    _instance = memService;
  }
}
