import 'package:collection/collection.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/notifications/notification_service.dart';
import 'package:mem/repositories/mem.dart';
import 'package:mem/repositories/mem_notification.dart';

import 'mem_service.dart';

class MemClient {
  final MemService _memService;
  final NotificationClientV3 _notificationClient;
  final NotificationService _notificationService;

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

          // TODO ここでnotificationClientを使って通知を登録する
          final savedMem = saved.mem;
          if (savedMem is SavedMem) {
            _notificationService.memReminder(savedMem);

            saved.notifications?.forEach((e) {
              if (e.isEnabled()) {
                _notificationService.memRepeatedReminder(savedMem, e);
              } else {
                _notificationService.memRepeatedReminder(savedMem, null);
              }
            });
          }

          final repeatMemNotification = saved.notifications
              ?.whereType<SavedMemNotification>()
              .singleWhereOrNull(
                (element) => element.isRepeated(),
              );
          if (repeatMemNotification != null) {
            await _notificationClient.registerMemRepeatNotification(
              saved.mem.name,
              repeatMemNotification,
              saved.notifications?.singleWhereOrNull(
                (element) => element.isRepeatByNDay(),
              ),
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

  Future<MemDetail> archive(Mem mem) => d(
        () async {
          // FIXME MemServiceの責務
          if (mem is SavedMem) {
            final archived = await _memService.archive(mem);

            return archived;
            // } else {
            //   // FIXME Memしかないので、子の状態が分からない
            //   _memService.save();
          }

          throw Error();
        },
        {
          "mem": mem,
        },
      );

  MemClient._(
    this._memService,
    this._notificationClient,
    this._notificationService,
  );

  static MemClient? _instance;

  factory MemClient() => v(
        () => _instance ??= MemClient._(
          MemService(),
          NotificationClientV3(),
          NotificationService(),
        ),
      );
}
