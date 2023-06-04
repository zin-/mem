import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/core/mem.dart';
import 'package:mem/gui/list_value_state_notifier.dart';
import 'package:mem/gui/value_state_notifier.dart';
import 'package:mem/logger/log_service_v2.dart';

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
      final raw = ref.watch(rawMemListProvider) ?? <Mem>[];

      return ValueStateNotifier(raw);
    },
  ),
);
