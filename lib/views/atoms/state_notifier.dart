import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/logger.dart';

class ValueStateNotifier<T> extends StateNotifier<T> {
  ValueStateNotifier(super.state);

  // TODO performance 値が変わっていたら通知する形にしたい
  T updatedBy(T value) => state = value;
}

class ListValueStateNotifier<T> extends ValueStateNotifier<List<T>?> {
  // FIXME filterはstateが持つものじゃない気がする
  final bool Function(T item)? filter;
  final int Function(T item1, T item2)? compare;

  ListValueStateNotifier(
    List<T>? state, {
    this.filter,
    this.compare,
  }) : super(state);

  @override
  List<T>? updatedBy(List<T>? value) => v(
        {'value': value},
        () => super.updatedBy(
          value == null
              ? value
              : List.of(value.where(filter ?? (_) => true))
                  .sorted(compare ?? (a, b) => 0),
        ),
      );

  void add(T item) => v(
        {'item': item},
        () {
          final tmp = List.of(state ?? <T>[]);
          tmp.add(item);
          updatedBy(tmp);
        },
      );

  void update(T item, bool Function(T item) where) => v(
        {'item': item, 'where': where},
        () {
          final tmp = List.of(state ?? <T>[]);

          final index = state?.indexWhere(where) ?? -1;
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
