import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification_repository.dart';
import 'package:mem/notifications/notification_service.dart';

import 'mem_item_repository.dart';
import 'mem_notification_repository.dart';
import 'mem_repository.dart';

class MemService {
  final MemRepository _memRepository;
  final MemItemRepository _memItemRepository;
  final MemNotificationRepository _memNotificationRepository;
  final NotificationService _notificationService;
  final NotificationRepository _notificationRepository;

  Future<Mem> fetchMemById(int memId) => i(
        () => _memRepository.shipById(memId),
        {'memId': memId},
      );

  Future<MemDetail> save(MemDetail memDetail, {bool undo = false}) => i(
        () async {
          final savedMem = memDetail.mem.isSaved() && !undo
              ? await _memRepository.replace(memDetail.mem)
              : await _memRepository.receive(memDetail.mem);
          _notificationService.memReminder(savedMem);

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
                        ? _memNotificationRepository
                            .replace(e..memId = savedMem.id)
                        : _memNotificationRepository
                            .receive(e..memId = savedMem.id))
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

  Future<MemDetail> archive(Mem mem) => i(
        () async {
          final archivedMem = await _memRepository.archive(mem);
          final archivedMemItems =
              (await _memItemRepository.archiveByMemId(archivedMem.id))
                  .map((e) => e.toV1())
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
                  .map((e) => e.toV1())
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

  static void reset(MemService? memService) {
    _instance = memService;
  }
}
