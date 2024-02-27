import 'package:collection/collection.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/core/mem_detail.dart';
import 'package:mem/core/mem_item.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/client.dart';
import 'package:mem/repositories/mem_notification.dart';

import 'mem_service.dart';

class MemClient {
  final MemService _memService;
  final NotificationClientV3 _notificationClient;

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

  MemClient._(this._memService, this._notificationClient);

  static MemClient? _instance;

  factory MemClient() => v(
        () => _instance ??= MemClient._(
          MemService(),
          NotificationClientV3(),
        ),
      );
}
