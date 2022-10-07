import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';
import 'package:mem/services/notification_service.dart';
import 'package:mem/views/mems/mems_state.dart';

final initialize = Provider.family<Future<void>, Function(int memId)>(
  (ref, showMemDetailPage) => v(
    {},
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
