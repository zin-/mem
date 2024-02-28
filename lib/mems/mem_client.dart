import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/notifications/mem_notifications.dart';
import 'package:mem/notifications/notification_repository.dart';
import 'package:mem/repositories/mem.dart';

import 'mem_service.dart';

class MemClient {
  final MemService _memService;
  final NotificationClientV3 _notificationClient;
  final NotificationRepository _notificationRepository;

  Future<MemDetail> save(
    Mem mem,
    List<MemItem> memItemList,
    List<MemNotification> memNotificationList,
  ) =>
      v(
        () async {
          final saved = await _memService.save(
            MemDetail(
              mem,
              memItemList,
              memNotificationList,
            ),
          );

          final savedMem = saved.mem;
          if (savedMem is SavedMem) {
            _notificationClient.registerMemNotifications(
              savedMem,
              saved.notifications,
            );
          }

          return saved;
        },
        {
          "mem": mem,
          "memItemList": memItemList,
          "memNotificationList": memNotificationList,
        },
      );

  Future<MemDetail> archive(Mem mem) => v(
        () async {
          // FIXME MemServiceの責務
          if (mem is SavedMem) {
            final archived = await _memService.archive(mem);

            final archivedMem = archived.mem;
            // FIXME archive後のMemDetailなので、必ずSavedMemのはず
            if (archivedMem is SavedMem) {
              _notificationClient.cancelMemNotifications(archivedMem);
            }

            return archived;
            // } else {
            //   // FIXME Memしかないので、子の状態が分からない
            //   _memService.save();
          }

          // coverage:ignore-line
          throw Error();
        },
        {
          "mem": mem,
        },
      );

  Future<MemDetail> unarchive(Mem mem) => v(
        () async {
          // FIXME MemServiceの責務
          if (mem is SavedMem) {
            final unarchived = await _memService.unarchive(mem);

            final unarchivedMem = unarchived.mem;
            // FIXME unarchive後のMemDetailなので、必ずSavedMemのはず
            if (unarchivedMem is SavedMem) {
              _notificationClient.registerMemNotifications(
                unarchivedMem,
                unarchived.notifications,
              );
            }

            return unarchived;
            // } else {
            //   // FIXME Memしかないので、子の状態が分からない
            //   _memService.save();
          }

          // coverage:ignore-line
          throw Error();
        },
        {
          "mem": mem,
        },
      );

  Future<bool> remove(int memId) => v(
        () async {
          final removeSuccess = await _memService.remove(memId);

          if (removeSuccess) {
            CancelAllMemNotifications.of(memId).forEach(
              (cancelNotification) =>
                  _notificationRepository.receive(cancelNotification),
            );
          }

          return removeSuccess;
        },
        {
          "memId": memId,
        },
      );

  MemClient._(
    this._memService,
    this._notificationClient,
    this._notificationRepository,
  );

  static MemClient? _instance;

  factory MemClient() => v(
        () => _instance ??= MemClient._(
          MemService(),
          NotificationClientV3(),
          NotificationRepository(),
        ),
      );
}
