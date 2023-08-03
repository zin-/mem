import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/components/list_value_state_notifier.dart';
import 'package:mem/core/act.dart';
import 'package:mem/logger/log_service.dart';

final actsProvider =
    StateNotifierProvider<ListValueStateNotifier<Act>, List<Act>?>(
  (ref) => v(() => ListValueStateNotifier(null)),
);
