import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/log_service_v2.dart';
import 'package:mem/notifications/notification_service.dart';
import 'package:mem/mems/mems_state.dart';

// FIXME ログで見たときこの関数名だと分かりづらい
final initialize = Provider.family<Future<void>, Function(int memId)>(
  (ref, showMemDetailPage) => v(
    () async {
      if (!ref.read(initialized)) {
        await NotificationService().initialize(
          showMemDetailPage: showMemDetailPage,
        );
        ref.read(initialized.notifier).updatedBy(true);
      }
    },
  ),
);
