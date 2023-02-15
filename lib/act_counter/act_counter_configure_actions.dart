import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/act_counter/act_counter_service.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/logger/i/api.dart';

final selectMem = Provider.family<void, MemId>(
  (ref, memId) => v(
    {'memId': memId},
    () {
      // TODO 選択を確定したらHome Widgetに情報を送る
      ActCounterService().createNew(memId);
    },
  ),
);
