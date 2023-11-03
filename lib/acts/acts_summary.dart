import 'package:collection/collection.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';

class ActsSummary {
  final Iterable<ActV2> _acts;

  ActsSummary(this._acts);

  late final groupedListByDate = _groupListByDate();
  late final int max = groupedListByDate.entries.fold<int>(
    0,
    (previousValue, element) => previousValue <= element.value.length
        ? element.value.length
        : previousValue,
  );
  late final int min = groupedListByDate.entries.fold<int>(
    max,
    (previousValue, element) => previousValue >= element.value.length
        ? element.value.length
        : previousValue,
  );

  Map<DateAndTime, List<ActV2>> _groupListByDate() => v(
        () {
          final groupedListByDate = _acts.groupListsBy(
            (element) => DateAndTime.from(element.period.start!),
          );

          final fillElements = <MapEntry<DateAndTime, List<ActV2>>>[];
          groupedListByDate.entries.forEachIndexed((index, element) {
            if (index != 0) {
              final diffInDays = groupedListByDate.entries
                  .elementAt(index - 1)
                  .key
                  .difference(element.key)
                  .inDays;
              if (diffInDays != 1) {
                fillElements.addAll(Iterable.generate(
                  diffInDays - 1,
                  (index) =>
                      MapEntry(element.key.add(Duration(days: index + 1)), []),
                ));
              }
            }
          });
          groupedListByDate.addEntries(fillElements);

          return Map.fromEntries(groupedListByDate.entries.sorted(
            (a, b) => a.key.compareTo(b.key),
          ));
        },
      );

  Map<DateAndTime, double> simpleMovingAverage(int n) => i(
        () {
          final sorted = groupedListByDate.entries
              .sorted((a, b) => b.key.compareTo(a.key));

          final result = <DateAndTime, double>{};
          for (var i = 0; i < sorted.length; i++) {
            final end = n + i;
            final ranged = end > sorted.length
                ? sorted.getRange(i, sorted.length)
                : sorted.getRange(i, end);
            final sum = ranged.fold<int>(
              0,
              (previousValue, element) => previousValue + element.value.length,
            );
            final ave = sum / ranged.length;

            result.putIfAbsent(sorted[i].key, () => ave);
          }

          return result;
        },
        n,
      );

  Map<DateAndTime, double> linearWeightedMovingAverage(int n) => i(
        () {
          final sorted = groupedListByDate.entries
              .sorted((a, b) => b.key.compareTo(a.key));

          final result = <DateAndTime, double>{};
          for (var i = 0; i < sorted.length; i++) {
            final end = n + i;
            final ranged = end > sorted.length
                ? sorted.getRange(i, sorted.length)
                : sorted.getRange(i, end);
            final sum = ranged.foldIndexed<int>(
              0,
              (index, previous, element) =>
                  previous + (ranged.length - index) * element.value.length,
            );

            final ave = sum / (ranged.length + (ranged.length + 1) / 2);

            result.putIfAbsent(sorted[i].key, () => ave);
          }

          return result;
        },
        n,
      );
}
