import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/act_counter/act_counter_service.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/log_service.dart';

final selectMem = Provider.family<void, MemId>(
  (ref, memId) => v(
    () async {
      await ActCounterService().createNew(memId);
    },
    {'memId': memId},
  ),
);
