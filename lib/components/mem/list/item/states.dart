import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';

enum MemListViewMode { singleSelection, multipleSelection }

final memListViewModeProvider = StateNotifierProvider<
    ValueStateNotifier<MemListViewMode?>, MemListViewMode?>(
  (ref) => v(
    () => ValueStateNotifier(null),
  ),
);

final selectedMemIdsProvider =
    StateNotifierProvider<ListValueStateNotifier<int>, List<int>?>(
  (ref) => v(
    () => ListValueStateNotifier<int>([]),
  ),
);
