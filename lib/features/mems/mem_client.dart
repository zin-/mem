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
          List<MemItemEntityV1>,
          List<MemNotificationEntity>?,
          TargetEntity?,
          List<MemRelationEntity>?,
          MemEntity,
        ),
        DateTime?
      )> save(
    MemEntityV1 mem,
    List<MemItemEntityV1> memItemList,
    List<MemNotificationEntityV1> memNotificationList,
    TargetEntity? target,
    List<MemRelationEntity>? memRelations,
  ) =>
      v(
        () async {
          final (
            _,
            savedMemItems,
            savedMemNotifications,
            savedTarget,
            savedMemRelations,
            memEntityV2
          ) = await _memService.save(
            (
              mem,
              memItemList,
              memNotificationList,
              target,
              memRelations,
            ),
          );

          final nextNotifyAt = await _notificationClient
              .registerMemNotifications(memEntityV2.toDomain());

          return (
            (
              savedMemItems,
              savedMemNotifications,
              savedTarget,
              savedMemRelations,
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
          "memRelations": memRelations,
        },
      );

  Future<MemEntity> archive(SavedMemEntityV1 memEntity) => v(
        () async {
          final archived = await _memService.archive(memEntity);

          _notificationClient.cancelMemNotifications(archived.id);

          return archived;
        },
        {
          'memEntity': memEntity,
        },
      );

  Future<MemEntity> unarchive(SavedMemEntityV1 memEntity) => v(
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
