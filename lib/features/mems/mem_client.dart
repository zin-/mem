import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/notifications/notification_client.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';

import 'mem_detail.dart';
import 'mem_entity.dart';
import 'mem_service.dart';

class MemClient {
  final MemService _memService;
  final NotificationClient _notificationClient;

  Future<MemDetail> save(
    MemEntityV2 mem,
    List<MemItemEntityV2> memItemList,
    List<MemNotificationEntityV2> memNotificationList,
    TargetEntity? target,
    List<MemRelationEntity>? memRelations,
  ) =>
      v(
        () async {
          final saved = await _memService.save(
            MemDetail(
              mem,
              memItemList,
              memNotificationList,
              target,
              memRelations,
            ),
          );

          _notificationClient.registerMemNotifications(
            (saved.mem as SavedMemEntityV2).id,
            savedMem: saved.mem as SavedMemEntityV2,
            savedMemNotifications:
                saved.notifications?.whereType<SavedMemNotificationEntityV2>(),
          );

          return saved;
        },
        {
          "mem": mem,
          "memItemList": memItemList,
          "memNotificationList": memNotificationList,
          "target": target,
          "memRelations": memRelations,
        },
      );

  Future<MemDetail> archive(SavedMemEntityV2 memEntity) => v(
        () async {
          final archived = await _memService.archive(memEntity);

          _notificationClient
              .cancelMemNotifications((archived.mem as SavedMemEntityV2).id);

          return archived;
        },
        {
          'memEntity': memEntity,
        },
      );

  Future<MemDetail> unarchive(SavedMemEntityV2 memEntity) => v(
        () async {
          final unarchived = await _memService.unarchive(memEntity);

          _notificationClient.registerMemNotifications(
            (unarchived.mem as SavedMemEntityV2).id,
            savedMem: unarchived.mem as SavedMemEntityV2,
            savedMemNotifications: unarchived.notifications
                ?.whereType<SavedMemNotificationEntityV2>(),
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
