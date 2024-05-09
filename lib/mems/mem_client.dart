import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/repositories/mem_notification.dart';

import 'mem_service.dart';

class MemClient {
  final MemService _memService;
  final NotificationClient _notificationClient;

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

          _notificationClient.registerMemNotifications(
            (saved.mem as SavedMem).id,
            savedMem: saved.mem as SavedMem,
            savedMemNotifications:
                saved.notifications?.whereType<SavedMemNotification>(),
          );

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
              _notificationClient.cancelMemNotifications(archivedMem.id);
            }

            return archived;
            // } else {
            //   // FIXME Memしかないので、子の状態が分からない
            //   _memService.save();
          }

          throw Error(); // coverage:ignore-line
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

            _notificationClient.registerMemNotifications(
              (unarchived.mem as SavedMem).id,
              savedMem: unarchived.mem as SavedMem,
              savedMemNotifications:
                  unarchived.notifications?.whereType<SavedMemNotification>(),
            );

            return unarchived;
            // } else {
            //   // FIXME Memしかないので、子の状態が分からない
            //   _memService.save();
          }

          throw Error(); // coverage:ignore-line
        },
        {
          "mem": mem,
        },
      );

  Future<bool> remove(int memId) => v(
        () async {
          final removeSuccess = await _memService.remove(memId);

          if (removeSuccess) {
            _notificationClient.cancelMemNotifications(memId);
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
  );

  static MemClient? _instance;

  factory MemClient() => v(
        () => _instance ??= MemClient._(
          MemService(),
          NotificationClient(),
        ),
      );
}
