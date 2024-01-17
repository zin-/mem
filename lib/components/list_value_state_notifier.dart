import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';

class ListValueStateNotifier<T> extends ValueStateNotifier<List<T>> {
  ListValueStateNotifier(
    super.state, {
    Future<List<T>>? initialFuture,
  }) {
    initialFuture?.then((value) => v(() => updatedBy(value), value));
  }

  void add(T item, {int? index}) => v(
        () {
          final tmp = List.of(state);

          tmp.insert(index ?? tmp.length, item);

          updatedBy(tmp);
        },
        {'item': item},
      );

  void upsertAll(Iterable<T> items, bool Function(T tmp, T item) where) => v(
        () {
          final tmp = List.of(state);

          for (var item in items) {
            final index = tmp.indexWhere(
              (tmpElement) => where(tmpElement, item),
            );
            if (index > -1) {
              tmp.replaceRange(index, index + 1, [item]);
            } else {
              tmp.add(item);
            }
          }

          updatedBy(tmp);
        },
        {'items': items},
      );

  void removeWhere(bool Function(T element) test) => v(
        () {
          final tmp = List.of(state);

          final index = state.indexWhere(test);
          if (index != -1) {
            tmp.removeAt(index);
          }

          updatedBy(tmp);
        },
      );
}
