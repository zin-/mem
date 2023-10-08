import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/value_state_notifier.dart';

final onSearchProvider =
    StateNotifierProvider.autoDispose<ValueStateNotifier<bool>, bool>(
  (ref) => ValueStateNotifier(false),
);

final searchTextProvider =
    StateNotifierProvider.autoDispose<ValueStateNotifier<String?>, String?>(
  (ref) => ValueStateNotifier(null),
);
