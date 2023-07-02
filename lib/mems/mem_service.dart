import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_item_repository_v2.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/notifications/notification_repository.dart';
import 'package:mem/notifications/notification_service.dart';

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

  Future<MemDetail> save(MemDetail memDetail, {bool undo = false}) => i(
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
        {'memDetail': memDetail},
      );

  Future<MemDetail> doneByMemId(int memId) => i(
        () async => save(MemDetail(
          (await fetchMemById(memId))..doneAt = DateTime.now(),
          [],
        )),
        {'memId': memId},
      );

  Future<MemDetail> undoneByMemId(int memId) => i(
        () async => save(MemDetail(
          (await fetchMemById(memId))..doneAt = null,
          [],
        )),
        {'memId': memId},
      );

  Future<Mem> fetchMemById(int memId) => i(
        () => _memRepository.shipById(memId),
        {'memId': memId},
      );

  Future<List<MemItem>> fetchMemItemsByMemId(int memId) => i(
        () async => (await _memItemRepository.shipByMemId(memId)).toList(),
        {'memId': memId},
      );

  Future<MemDetail> archive(Mem mem) => i(
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
        {'mem': mem},
      );

  Future<MemDetail> unarchive(Mem mem) => i(
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
        {'mem': mem},
      );

  Future<bool> remove(int memId) => i(
        () async {
          await _memItemRepository.wasteByMemId(memId);
          await _memRepository.wasteById(memId);

          // FIXME 関数内でMemを保持していないためRepositoryを参照している
          // discardされた時点でMemは存在しなくなるため、どちらにせよ無理筋かも
          NotificationRepository().discard(memId);

          return true;
        },
        {'memId': memId},
      );

  static void reset(MemService? memService) {
    _instance = memService;
  }
}
