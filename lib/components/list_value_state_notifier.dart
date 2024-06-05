import 'package:mem/components/value_state_notifier.dart';
import 'package:mem/logger/log_service.dart';

class ListValueStateNotifier<T> extends ValueStateNotifier<List<T>> {
  ListValueStateNotifier(
    super.state, {
    void Function(
      List<T> current,
      ListValueStateNotifier<T> notifier,
    )? initializer,
  }) {
    if (initializer != null) {
      if (mounted) {
        initializer.call(state, this);
      } else {
// coverage:ignore-start
        warn("${super.toString()}. No update.");
// coverage:ignore-end
      }
    }
  }

  void add(T item, {int? index}) => v(
        () {
          final tmp = List.of(state);

          tmp.insert(index ?? tmp.length, item);

          updatedBy(tmp);
        },
        {'item': item},
      );

  List<T> upsertAll(
    Iterable<T> updatingItems,
    bool Function(T current, T updating) where, {
    bool Function(T current)? removeWhere,
  }) =>
      v(
        () {
          final tmp = List.of(state);

          if (removeWhere != null) {
            tmp.removeWhere((element) => removeWhere(element));
          }

          for (final item in updatingItems) {
            final index = tmp.indexWhere(
              (tmpElement) => where(tmpElement, item),
            );
            if (index > -1) {
              tmp.replaceRange(index, index + 1, [item]);
            } else {
              tmp.add(item);
            }
          }

          return updatedBy(tmp);
        },
        {"updatingItems": updatingItems},
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
