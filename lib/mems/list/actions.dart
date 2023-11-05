import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/framework/repository/condition/in.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/repositories/mem_notification_repository.dart';
import 'package:mem/mems/states.dart';

final fetchMemNotifications = Provider.autoDispose
    .family<Future<Iterable<SavedMemNotificationV2>>, Iterable<int>>(
  (ref, memIds) => v(
    () => memIds.isEmpty
        ? Future.value([])
        : MemNotificationRepository()
            .ship(In(defFkMemNotificationsMemId.name, memIds))
      ..then(
        (value) => ref.read(memNotificationsProvider.notifier).upsertAll(
              value,
              (tmp, item) =>
                  tmp is SavedMemNotificationV2 &&
                  item is SavedMemNotificationV2 &&
                  tmp.id == item.id,
            ),
      ),
    memIds,
  ),
);
final fetchActiveActs = Provider(
  (ref) => v(
    () => ActRepository().shipActive().then(
          (activeActs) => ref.read(actsProvider.notifier).updatedBy(activeActs),
        ),
  ),
);
