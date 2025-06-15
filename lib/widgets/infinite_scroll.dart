import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/view/value_state_notifier.dart';
import 'package:mem/features/logger/log_service.dart';

class InfiniteScrollController {
  final ScrollController scrollController;
  final WidgetRef ref;
  final int? memId;
  final double threshold;

  InfiniteScrollController({
    required this.scrollController,
    required this.ref,
    this.memId,
    this.threshold = 0.6,
  }) {
    scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!scrollController.hasClients) return;

    if (scrollController.position.maxScrollExtent == 0.0 ||
        scrollController.position.pixels >
            scrollController.position.maxScrollExtent * threshold) {
      final c = ref.read(currentPage(memId));

      if (c < ref.read(maxPage(memId))) {
        Future.microtask(() {
          if (ref.read(isLoading(memId))) {
            ref.watch(isLoading(memId)); // coverage:ignore-line
          } else {
            ref.read(currentPage(memId).notifier).updatedBy(c + 1);
            ref.read(isUpdating(memId).notifier).updatedBy(false);
          }
        });
      }
    }
  }

  void dispose() {
    scrollController.removeListener(_onScroll);
  }
}

final isLoading = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<bool>, bool, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(false),
    {"memId": memId},
  ),
);

final isUpdating = StateNotifierProvider.autoDispose
    .family<ValueStateNotifier<bool>, bool, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(false),
    {"memId": memId},
  ),
);

final currentPage =
    StateNotifierProvider.family<ValueStateNotifier<int>, int, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(1),
    {"memId": memId},
  ),
);

final maxPage =
    StateNotifierProvider.family<ValueStateNotifier<int>, int, int?>(
  (ref, memId) => v(
    () => ValueStateNotifier(0),
    {"memId": memId},
  ),
);
