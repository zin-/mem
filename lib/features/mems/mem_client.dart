import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';

import 'mem_entity.dart';
import 'mem_service.dart';

class MemClient {
  final MemService _memService;
  final NotificationClient _notificationClient;

  Future<
      (
        (
          MemEntity,
          List<MemItemEntity>,
          List<MemNotificationEntity>?,
          TargetEntity?,
          List<MemRelationEntity>?
        ),
        DateTime?
      )> save(
    MemEntity mem,
    List<MemItemEntity> memItemList,
    List<MemNotificationEntity> memNotificationList,
    TargetEntity? target,
    List<MemRelationEntity>? memRelations,
  ) =>
      v(
        () async {
          final saved = await _memService.save(
            (
              mem,
              memItemList,
              memNotificationList,
              target,
              memRelations,
            ),
          );

          final nextNotifyAt =
              await _notificationClient.registerMemNotifications(
            (saved.$1 as SavedMemEntity).id,
            savedMem: saved.$1 as SavedMemEntity,
            savedMemNotifications:
                saved.$3?.whereType<SavedMemNotificationEntity>(),
          );

          return (saved, nextNotifyAt);
        },
        {
          "mem": mem,
          "memItemList": memItemList,
          "memNotificationList": memNotificationList,
          "target": target,
          "memRelations": memRelations,
        },
      );

  Future<
      (
        MemEntity,
        List<MemItemEntity>,
        List<MemNotificationEntity>?,
        TargetEntity?,
        List<MemRelationEntity>?
      )> archive(SavedMemEntity memEntity) => v(
        () async {
          final archived = await _memService.archive(memEntity);

          _notificationClient
              .cancelMemNotifications((archived.$1 as SavedMemEntity).id);

          return archived;
        },
        {
          'memEntity': memEntity,
        },
      );

  Future<
      (
        MemEntity,
        List<MemItemEntity>,
        List<MemNotificationEntity>?,
        TargetEntity?,
        List<MemRelationEntity>?
      )> unarchive(SavedMemEntity memEntity) => v(
        () async {
          final unarchived = await _memService.unarchive(memEntity);

          _notificationClient.registerMemNotifications(
            (unarchived.$1 as SavedMemEntity).id,
            savedMem: unarchived.$1 as SavedMemEntity,
            savedMemNotifications:
                unarchived.$3?.whereType<SavedMemNotificationEntity>(),
          );

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

  factory MemClient() => v(
        () => _instance ??= MemClient._(
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
