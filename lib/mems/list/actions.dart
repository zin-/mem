import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_notification_repository.dart';
import 'package:mem/mems/states.dart';
import 'package:mem/repositories/i/conditions/in.dart';

final fetchMemNotifications = Provider.autoDispose
    .family<Future<Iterable<MemNotification>>, Iterable<int>>(
  (ref, memIds) => v(
    () => memIds.isEmpty
        ? Future.value([])
        : MemNotificationRepository().ship(In(defFkMemNotificationsMemId.name, memIds))
      ..then(
        (value) => ref.read(memNotificationsProvider.notifier).upsertAll(
              value,
              (tmp, item) => tmp.id == item.id,
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
