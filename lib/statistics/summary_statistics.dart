import 'package:collection/collection.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';


abstract class SummaryStatistics {
  Map<DateAndTime, List<dynamic>> get groupedListByDate;

  SummaryStatistics();

  double getValue(List<dynamic> items);

  late final double max = groupedListByDate.entries.fold<double>(
    0,
    (previousValue, element) {
      final value = getValue(element.value);
      return previousValue <= value ? value : previousValue;
    },
  );

  late final double min = groupedListByDate.entries.fold<double>(
    max,
    (previousValue, element) {
      final value = getValue(element.value);
      return previousValue >= value ? value : previousValue;
    },
  );

  late final double average = groupedListByDate.entries.isEmpty
      ? 0
      : groupedListByDate.entries.map((e) => getValue(e.value)).average;

  Map<DateAndTime, double> simpleMovingAverage(int n) => v(
        () {
          final sorted = groupedListByDate.entries
              .sorted((a, b) => b.key.compareTo(a.key));

          final result = <DateAndTime, double>{};
          for (var i = 0; i < sorted.length; i++) {
            final end = n + i;
            final ranged = end > sorted.length
                ? sorted.getRange(i, sorted.length)
                : sorted.getRange(i, end);
            final sum = ranged.fold<double>(
              0,
              (previousValue, element) =>
                  previousValue + getValue(element.value),
            );
            final ave = sum / ranged.length;

            result.putIfAbsent(sorted[i].key, () => ave);
          }

          return result;
        },
        n,
      );

  Map<DateAndTime, double> linearWeightedMovingAverage(int n) => v(
        () {
          final sorted = groupedListByDate.entries
              .sorted((a, b) => b.key.compareTo(a.key));

          final result = <DateAndTime, double>{};
          for (var i = 0; i < sorted.length; i++) {
            final end = n + i;
            final ranged = end > sorted.length
                ? sorted.getRange(i, sorted.length)
                : sorted.getRange(i, end);
            final sum = ranged.foldIndexed<double>(
              0,
              (index, previous, element) =>
                  previous + (ranged.length - index) * getValue(element.value),
            );

            final ave = sum / (ranged.length * (ranged.length + 1) / 2);

            result.putIfAbsent(sorted[i].key, () => ave);
          }

          return result;
        },
        n,
      );
}
