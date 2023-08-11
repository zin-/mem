import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_service.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/core/act.dart';
import 'package:mem/logger/log_service.dart';

final deleteAct = Provider.autoDispose.family<void, ActIdentifier>(
  (ref, actIdentifier) => v(
    () async {
      ActService().delete(actIdentifier.actId).then((value) {
        ref
            .read(actsProvider.notifier)
            .removeWhere((item) => item.id == value.id);
      });
    },
    actIdentifier,
  ),
);
