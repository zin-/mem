import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/list_value_state_notifier.dart';
import 'package:mem/gui/value_state_notifier.dart';
import 'package:mem/logger/log_service_v2.dart';
import 'package:mem/mems/mem_list_page_states.dart';

final rawMemListProvider =
    StateNotifierProvider<ListValueStateNotifier<Mem>, List<Mem>?>(
  (ref) => d(
    () {
      return ListValueStateNotifier<Mem>(null);
    },
  ),
);

final memListProviderV2 =
    StateNotifierProvider<ValueStateNotifier<List<Mem>>, List<Mem>>(
  (ref) => d(
    () {
      final rawMemList = ref.watch(rawMemListProvider) ?? <Mem>[];

      final showNotArchived = ref.watch(showNotArchivedProvider);
      final showArchived = ref.watch(showArchivedProvider);
      final showNotDone = ref.watch(showNotDoneProvider);
      final showDone = ref.watch(showDoneProvider);

      final filtered = rawMemList.where((mem) {
        if (showNotArchived == showArchived) {
          return true;
        } else {
          return showArchived ? mem.isArchived() : !mem.isArchived();
        }
      }).where((mem) {
        if (showNotDone == showDone) {
          return true;
        } else {
          return showDone ? mem.isDone() : !mem.isDone();
        }
      }).toList();

      return ValueStateNotifier(filtered);
    },
  ),
);
