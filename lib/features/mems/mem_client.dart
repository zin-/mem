import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mem/features/mem_preposts/mem_prepost_entity.dart';

import 'mem_entity.dart';
import 'mem_service.dart';
import 'mem_view_data.dart';

class MemClient {
  final MemService _memService;
  final NotificationClient _notificationClient;

  Future<
      (
        (
          List<MemItemEntityV1>,
          List<MemNotificationEntity>?,
          TargetEntityV1?,
          List<MemPrePostEntityV1>?,
          MemEntity,
        ),
        DateTime?
      )> save(
    MemViewData mem,
    List<MemItemEntityV1> memItemList,
    List<MemNotificationEntityV1> memNotificationList,
    TargetEntityV1? target,
    List<MemPrePostEntityV1>? memPrePosts,
  ) =>
      v(
        () async {
          final (
            savedMemItems,
            savedMemNotifications,
            savedTarget,
            savedMemPrePosts,
            memEntityV2
          ) = await _memService.save(
            (
              mem,
              memItemList,
              memNotificationList,
              target,
              memPrePosts,
            ),
          );

          final nextNotifyAt = await _notificationClient
              .registerMemNotifications(memEntityV2.toDomain());

          return (
            (
              savedMemItems,
              savedMemNotifications,
              savedTarget,
              savedMemPrePosts,
              memEntityV2
            ),
            nextNotifyAt
          );
        },
        {
          "mem": mem,
          "memItemList": memItemList,
          "memNotificationList": memNotificationList,
          "target": target,
          "memPrePosts": memPrePosts,
        },
      );

  Future<MemEntity> archive(MemEntity memEntity) => v(
        () async {
          final archived = await _memService.archive(memEntity);

          _notificationClient.cancelMemNotifications(archived.id);

          return archived;
        },
        {
          'memEntity': memEntity,
        },
      );

  Future<MemEntity> unarchive(MemEntity memEntity) => v(
        () async {
          final unarchived = await _memService.unarchive(memEntity);

          _notificationClient.registerMemNotifications(unarchived.toDomain());

          return unarchived;
        },
        {
          'memEntity': memEntity,
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

  factory MemClient({MemClient? mock}) => v(
        () => _instance ??= mock ??
            MemClient._(
              MemService(),
              NotificationClient(),
            ),
      );

  static void resetSingleton() => v(
        () {
          NotificationClient.resetSingleton();
          _instance = null;
        },
        {
          '_instance': _instance,
        },
      );
}
