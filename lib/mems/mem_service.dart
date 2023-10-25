import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_item_repository.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification_repository.dart';
import 'package:mem/notifications/notification_service.dart';
import 'package:mem/repositories/mem_notification_repository.dart';
import 'package:mem/repositories/mem_repository.dart';

class MemService {
  final MemRepository _memRepository;
  final MemItemRepository _memItemRepository;
  final MemNotificationRepository _memNotificationRepository;
  final NotificationService _notificationService;
  final NotificationRepository _notificationRepository;

  Future<MemDetail> save(MemDetail memDetail, {bool undo = false}) => i(
        () async {
          final savedMem = (memDetail.mem.isSaved() && !undo
                  ? await _memRepository
                      .replace(SavedMemV2.fromV1(memDetail.mem))
                  : await _memRepository.receive(MemV2.fromV1(memDetail.mem)))
              .toV1();
          _notificationService.memReminder(SavedMemV2.fromV1(savedMem));

          final savedMemItems = (await Future.wait(memDetail.memItems.map((e) =>
                  (e.isSaved() && !undo
                      ? _memItemRepository.replace(
                          SavedMemItemV2.fromV1(e..memId = savedMem.id))
                      : _memItemRepository
                          .receive(MemItemV2.fromV1(e..memId = savedMem.id))))))
              .map((e) => e.toV1())
              .toList();

          final savedMemNotifications = memDetail.notifications == null
              ? null
              : await Future.wait(memDetail.notifications!.map((e) {
                  if (e.time == null) {
                    if (e.isSaved()) {
                      _memNotificationRepository.wasteById(e.id);
                    }
                    _notificationService.memRepeatedReminder(savedMem, null);
                    return Future(
                        () => MemNotification(e.type, e.time, e.message));
                  } else {
                    return (e.isSaved() && !undo
                            ? _memNotificationRepository.replace(
                                SavedMemNotificationV2.fromV1(
                                    e..memId = savedMem.id))
                            : _memNotificationRepository.receive(
                                MemNotificationV2.fromV1(
                                    e..memId = savedMem.id)))
                        .then((value) => value.toV1())
                      ..then(
                        (value) => _notificationService.memRepeatedReminder(
                          savedMem,
                          value,
                        ),
                      );
                  }
                }));

          return MemDetail(
            savedMem,
            savedMemItems,
            savedMemNotifications,
          );
        },
        {'memDetail': memDetail},
      );

  Future<MemDetail> doneByMemId(int memId) => i(
        () async => save(MemDetail(
          (await _memRepository.shipById(memId))
              .copiedWith(doneAt: () => DateTime.now())
              .toV1(),
          [],
        )),
        {'memId': memId},
      );

  Future<MemDetail> undoneByMemId(int memId) => i(
        () async => save(MemDetail(
          (await _memRepository.shipById(memId))
              .copiedWith(doneAt: () => null)
              .toV1(),
          [],
        )),
        {'memId': memId},
      );

  Future<MemDetail> archive(Mem mem) => i(
        () async {
          final archivedMem = await _memRepository
              .archive(SavedMemV2.fromV1(mem))
              .then((value) => value.toV1());
          final archivedMemItems =
              (await _memItemRepository.archiveByMemId(archivedMem.id))
                  .map((e) => e.toV1())
                  .toList();

          _notificationService.memReminder(SavedMemV2.fromV1(archivedMem));

          return MemDetail(
            archivedMem,
            archivedMemItems,
          );
        },
        {'mem': mem},
      );

  Future<MemDetail> unarchive(Mem mem) => i(
        () async {
          final unarchivedMem = await _memRepository
              .unarchive(SavedMemV2.fromV1(mem))
              .then((value) => value.toV1());
          final unarchivedMemItems =
              (await _memItemRepository.unarchiveByMemId(unarchivedMem.id))
                  .map((e) => e.toV1())
                  .toList();

          _notificationService.memReminder(SavedMemV2.fromV1(unarchivedMem));

          return MemDetail(
            unarchivedMem,
            unarchivedMemItems,
          );
        },
        {'mem': mem},
      );

  Future<bool> remove(int memId) => i(
        () async {
          await _memNotificationRepository.wasteByMemId(memId);
          await _memItemRepository.wasteByMemId(memId);
          await _memRepository.wasteById(memId);

          CancelAllMemNotifications.of(memId).forEach(
            (cancelNotification) =>
                _notificationRepository.receive(cancelNotification),
          );

          return true;
        },
        {'memId': memId},
      );

  MemService._(
    this._memRepository,
    this._memItemRepository,
    this._memNotificationRepository,
    this._notificationService,
    this._notificationRepository,
  );

  static MemService? _instance;

  factory MemService() => _instance ??= MemService._(
        MemRepository(),
        MemItemRepository(),
        MemNotificationRepository(),
        NotificationService(),
        NotificationRepository(),
      );
}
