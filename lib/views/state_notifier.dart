import 'package:flutter_riverpod/flutter_riverpod.dart';

class ValueStateNotifier<T> extends StateNotifier<T> {
  ValueStateNotifier(super.state);

  // TODO performance 値が変わっていたら通知する形にしたい
  T updatedBy(T value) => state = value;
}

class ListValueStateNotifier<T> extends ValueStateNotifier<List<T>> {
  final bool Function(T item)? filter;

  ListValueStateNotifier(
    List<T> state, {
    this.filter,
  }) : super(state);

  @override
  List<T> updatedBy(List<T> value) {
    final filtered = List.of(value)
        .where(
          filter ?? (_) => true,
        )
        .toList();
    return super.updatedBy(filtered);
  }

  void add(T item) {
    final tmp = List.of(state);
    tmp.add(item);
    updatedBy(tmp
        .where(
          (element) => filter?.call(element) ?? true,
        )
        .toList());
  }

  void updateWhere(T item, bool Function(T item) where) {
    final tmp = List.of(state);

    final index = state.indexWhere(where);
    if (index == -1) {
      add(item);
    } else {
      tmp.replaceRange(index, index + 1, [item]);
      updatedBy(tmp
          .where(
            (element) => filter?.call(element) ?? true,
          )
          .toList());
    }
  }
}
