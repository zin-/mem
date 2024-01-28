import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/value_state_notifier.dart';

final searchTextProvider =
    StateNotifierProvider.autoDispose<ValueStateNotifier<String?>, String?>(
  (ref) => ValueStateNotifier(null),
);
