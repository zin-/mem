import 'package:flutter_riverpod/legacy.dart';
import 'package:mem/framework/view/list_value_state_notifier.dart';
import 'package:mem/features/logger/log_service.dart';

final selectedMemIdsProvider =
    StateNotifierProvider<ListValueStateNotifier<int>, List<int>>(
  (ref) => v(
    () => ListValueStateNotifier<int>([]),
  ),
);
