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

  Future<MemDetail> save(MemDetail memDetail, {bool undo = false}) => t(
        {'memDetail': memDetail},
        () async {
          Mem savedMem;
          if (memDetail.mem.isSaved() && !undo) {
            savedMem = await _memRepository.replace(memDetail.mem);
          } else {
            savedMem = await _memRepository.receive(memDetail.mem);
          }

          final savedMemItems = (await Future.wait(memDetail.memItems.map((e) =>
                  (e.isSaved() && !undo
                          ? _memItemRepository.replace
                          : _memItemRepository.receive)
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

  Future<Mem> fetchMemById(int memId) => t(
        {'memId': memId},
        () => _memRepository.shipById(memId),
      );

  Future<List<MemItem>> fetchMemItemsByMemId(int memId) => t(
        {'memId': memId},
        () async => (await _memItemRepository.shipByMemId(memId)).toList(),
      );

  Future<MemDetail> archive(Mem mem) => t(
        {'mem': mem},
        () async {
          final archivedMem = await _memRepository.archive(mem);
          final archivedMemItems =
              (await _memItemRepository.archiveByMemId(archivedMem.id))
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
          final unarchivedMem = await _memRepository.unarchive(mem);
          final unarchivedMemItems =
              (await _memItemRepository.unarchiveByMemId(unarchivedMem.id))
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
          await _memItemRepository.wasteByMemId(memId);
          await _memRepository.wasteById(memId);

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
