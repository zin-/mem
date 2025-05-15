import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/counter/act_counter_client.dart';
import 'package:mem/features/logger/log_service.dart';

final selectMem = Provider.family<void, int>(
  (ref, memId) => v(
    () async => await ActCounterClient().createNew(memId),
    {
      "memId": memId,
    },
  ),
);
