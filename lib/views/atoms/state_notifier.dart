import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ValueStateNotifier<T> extends StateNotifier<T> {
  ValueStateNotifier(super.state);

  // TODO performance 値が変わっていたら通知する形にしたい
  T updatedBy(T value) => state = value;
}

class ListValueStateNotifier<T> extends ValueStateNotifier<List<T>> {
  // FIXME filterはstateが持つものじゃない気がする
  final bool Function(T item)? filter;
  final int Function(T item1, T item2)? compare;

  ListValueStateNotifier(
    List<T> state, {
    this.filter,
    this.compare,
  }) : super(state);

  @override
  List<T> updatedBy(List<T> value) =>
      super.updatedBy(List.of(value.where(filter ?? (_) => true))
          .sorted(compare ?? (a, b) => 0));

  void add(T item, bool Function(T item) where) {
    final tmp = List.of(state);

    final index = state.indexWhere(where);
    if (index == -1) {
      tmp.add(item);
    } else {
      tmp.replaceRange(index, index + 1, [item]);
    }
    updatedBy(tmp);
  }

  void remove(bool Function(T item) where) {
    final tmp = List.of(state);

    final index = state.indexWhere(where);
    if (index != -1) {
      tmp.removeAt(index);
    }

    updatedBy(tmp);
  }
}
