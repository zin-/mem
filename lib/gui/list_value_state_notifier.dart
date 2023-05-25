import 'package:mem/gui/value_state_notifier.dart';
import 'package:mem/logger/i/api.dart';

class ListValueStateNotifier<T> extends ValueStateNotifier<List<T>?> {
  ListValueStateNotifier(super.state);

  void add(T item, {int? index}) => v(
        {'item': item},
        () {
          final tmp = List.of(state ?? <T>[]);

          tmp.insert(index ?? tmp.length, item);

          updatedBy(tmp);
        },
      );

  void upsertAll(Iterable<T> items, bool Function(T tmp, T item) where) => v(
        {'items': items},
        () {
          final tmp = List.of(state ?? <T>[]);

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
      );

  void removeWhere(bool Function(T item) where) => v(
        {},
        () {
          final tmp = List.of(state ?? <T>[]);

          final index = state?.indexWhere(where) ?? -1;
          if (index != -1) {
            tmp.removeAt(index);
          }

          updatedBy(tmp);
        },
      );
}
