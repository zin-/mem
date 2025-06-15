import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/framework/view/value_state_notifier.dart';
import 'package:mem/features/logger/log_service.dart';

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
