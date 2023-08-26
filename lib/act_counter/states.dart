import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';

final selectedMemIdsProvider =
    StateNotifierProvider<ListValueStateNotifier<int>, List<int>?>(
  (ref) => v(
    () => ListValueStateNotifier<int>([]),
  ),
);
