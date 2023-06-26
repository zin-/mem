import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/list_value_state_notifier.dart';
import 'package:mem/gui/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';

enum MemListViewMode { singleSelection, multipleSelection }

final memListViewModeProvider = StateNotifierProvider<
    ValueStateNotifier<MemListViewMode?>, MemListViewMode?>(
  (ref) => v(
    () => ValueStateNotifier(null),
  ),
);

final selectedMemIdsProvider =
    StateNotifierProvider<ListValueStateNotifier<MemId>, List<MemId>?>(
  (ref) => v(
    () => ListValueStateNotifier<MemId>([]),
  ),
);
