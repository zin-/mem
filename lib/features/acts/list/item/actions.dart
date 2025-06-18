import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/client.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/features/logger/log_service.dart';

final _actsClient = ActsClient();

final deleteAct = Provider.autoDispose.family<void, int>(
  (ref, actId) => v(
    () async {
      _actsClient.delete(actId).then((value) {
        ref
            .read(actsProvider.notifier)
            .removeWhere((item) => item.id == value.id);
      });
    },
    actId,
  ),
);
