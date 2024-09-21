import 'package:mem/mems/mem.dart';
import 'package:mem/mems/mem_detail.dart';
import 'package:mem/mems/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification_client.dart';
import 'package:mem/mems/mem_entity.dart';
import 'package:mem/mems/mem_item_entity.dart';
import 'package:mem/mems/mem_notification_entity.dart';

import 'mem_service.dart';

class MemClient {
  final MemService _memService;
  final NotificationClient _notificationClient;

  Future<MemDetail> save(
    MemEntity mem,
    List<MemItemEntity> memItemList,
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
            (saved.mem as SavedMemEntity).id,
            savedMem: saved.mem as SavedMemEntity,
            savedMemNotifications:
                saved.notifications?.whereType<SavedMemNotificationEntity>(),
          );

          return saved;
        },
        {
          "mem": mem,
          "memItemList": memItemList,
          "memNotificationList": memNotificationList,
        },
      );

  Future<MemDetail> archive(MemEntity mem) => v(
        () async {
          // FIXME MemServiceの責務
          if (mem is SavedMemEntity) {
            final archived = await _memService.archive(mem);

            final archivedMem = archived.mem;
            // FIXME archive後のMemDetailなので、必ずSavedMemのはず
            if (archivedMem is SavedMemEntity) {
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
          // FIXME 保存済みかどうかを判定するのはMemServiceの責務？
          //  Client sideで判定できるものではない気がする
          if (mem is SavedMemEntity) {
            final unarchived = await _memService.unarchive(mem);

            _notificationClient.registerMemNotifications(
              (unarchived.mem as SavedMemEntity).id,
              savedMem: unarchived.mem as SavedMemEntity,
              savedMemNotifications: unarchived.notifications
                  ?.whereType<SavedMemNotificationEntity>(),
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
