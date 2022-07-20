import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/mem_detail/state_notifier.dart';

class MemState extends ValueStateNotifier<Map<String, dynamic>> {
  MemState(super.state);

  @override
  Map<String, dynamic> updatedBy(Map<String, dynamic> value) {
    final newValue = Map.of(value);
    return super.updatedBy(newValue);
  }
}

final memProvider =
    StateNotifierProvider.family<MemState, Map<String, dynamic>, int?>(
  (ref, memId) {
    print(memId);
    return MemState({});
  },
);
