import 'package:flutter_riverpod/flutter_riverpod.dart';

class ValueStateNotifier<T> extends StateNotifier<T> {
  ValueStateNotifier(super.state);

  T updatedBy(T value) => state = value;
}

class ListValueStateNotifier<T> extends ValueStateNotifier<List<T>> {
  ListValueStateNotifier(super.state);

  add(T item) {
    final tmp = List.of(state);
    tmp.add(item);
    state = tmp;
  }

  updateWhere(T item, bool Function(T item) where) {
    final index = state.indexWhere(where);

    final tmp = List.of(state);
    tmp.replaceRange(index, index + 1, [item]);
    state = tmp;
  }
}
