import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/act_service.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/core/act.dart';
import 'package:mem/logger/log_service.dart';

final _actsService = ActService();

final actsProvider =
    StateNotifierProvider<ListValueStateNotifier<SavedAct>, List<SavedAct>>(
  (ref) => v(() => ListValueStateNotifier([])),
);

final isLoading = StateNotifierProvider<ValueStateNotifier<bool>, bool>(
    (ref) => ValueStateNotifier(false));
final isUpdating = StateNotifierProvider<ValueStateNotifier<bool>, bool>(
    (ref) => ValueStateNotifier(false));
final currentPage = StateNotifierProvider<ValueStateNotifier<int>, int>(
    (ref) => ValueStateNotifier(1));
final maxPage = StateNotifierProvider<ValueStateNotifier<int>, int>(
    (ref) => ValueStateNotifier(0));

final actListProvider = StateNotifierProvider.autoDispose
    .family<ListValueStateNotifier<Act>, List<Act>, int?>(
  (ref, memId) => v(
    () {
      final u = ref.read(isUpdating);
      if (u) {
        ref.watch(isUpdating);
      } else {
        Future.microtask(() async {
          ref.read(isLoading.notifier).updatedBy(true);

          final latest = await _actsService.fetch(memId, 1);
          final c = ref.read(currentPage);

          ListWithTotalPage<SavedAct>? byPage;
          if (c != 1) {
            byPage = await _actsService.fetch(memId, c);
          }

          ref.read(isLoading.notifier).updatedBy(false);
          ref.read(isUpdating.notifier).updatedBy(true);
          ref.read(maxPage.notifier).updatedBy(latest.totalPage);
          ref.read(actsProvider.notifier).upsertAll(
            [...latest.list, if (byPage != null) ...byPage.list],
            (current, updating) => current.id == updating.id,
          );
        });
      }

      return ListValueStateNotifier(
        ref
            .watch(actsProvider)
            .where((act) => memId == null || act.memId == memId)
            .toList()
            .sorted((a, b) => b.period.compareTo(a.period)),
      );
    },
    {
      "memId": memId,
    },
  ),
);
