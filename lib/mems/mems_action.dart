import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/notifications/notification_repository.dart';
import 'package:mem/notifications/notification_service.dart';
import 'package:mem/mems/mems_state.dart';

final initializeNotification =
    Provider.family<Future<void>, Function(int memId)>(
  (ref, showMemDetailPage) => v(
    () async {
      if (!ref.read(initialized)) {
        await NotificationRepository().initialize(
          notificationActionHandler,
          showMemDetailPage,
        );
        ref.read(initialized.notifier).updatedBy(true);
      }
    },
  ),
);
