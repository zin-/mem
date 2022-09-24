import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';

class ValueStateNotifier<T> extends StateNotifier<T> {
  ValueStateNotifier(super.state);

  // TODO performance 値が変わっていたら通知する形にしたい
  T updatedBy(T value) => state = value;

  @override
  String toString() => 'state: $state';
}

class ListValueStateNotifier<T> extends ValueStateNotifier<List<T>?> {
  ListValueStateNotifier(List<T>? state) : super(state);

  void add(T item) => v(
        {'item': item},
        () {
          final tmp = List.of(state ?? <T>[]);

          tmp.add(item);

          updatedBy(tmp);
        },
      );

  void upsert(T item, bool Function(T item) where) => v(
        {'item': item, 'where': where},
        () {
          final tmp = List.of(state ?? <T>[]);

          final index = tmp.indexWhere(where);
          if (index > -1) {
            tmp.replaceRange(index, index + 1, [item]);
            updatedBy(tmp);
          } else {
            add(item);
          }
        },
      );

  void remove(bool Function(T item) where) {
    final tmp = List.of(state ?? <T>[]);

    final index = state?.indexWhere(where) ?? -1;
    if (index != -1) {
      tmp.removeAt(index);
    }

    updatedBy(tmp);
  }
}
