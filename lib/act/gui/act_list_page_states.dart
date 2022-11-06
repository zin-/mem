import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger/api.dart';
import 'package:mem/view/_atom/state_notifier.dart';

import '../domain/act.dart';

final actListProvider =
    StateNotifierProvider<ListValueStateNotifier<Act>, List<Act>?>(
  (ref) => v(
    {},
    () => ListValueStateNotifier(null),
  ),
);
