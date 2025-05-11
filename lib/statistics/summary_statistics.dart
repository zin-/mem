import 'package:collection/collection.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';

class SummaryStatistics {
  final Map<DateAndTime, List<dynamic>> groupedListByDate;

  SummaryStatistics(this.groupedListByDate);

  late final int max = groupedListByDate.entries.fold<int>(
    0,
        (previousValue, element) =>
    previousValue <= element.value.length
        ? element.value.length
        : previousValue,
  );

  late final int min = groupedListByDate.entries.fold<int>(
    max,
        (previousValue, element) =>
    previousValue >= element.value.length
        ? element.value.length
        : previousValue,
  );

  late final double average = groupedListByDate.entries.isEmpty
      ? 0
      : groupedListByDate.entries
      .map((e) => e.value.length)
      .average;

  Map<DateAndTime, double> simpleMovingAverage(int n) =>
      v(
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
                  (previousValue, element) =>
              previousValue + element.value.length,
            );
            final ave = sum / ranged.length;

            result.putIfAbsent(sorted[i].key, () => ave);
          }

          return result;
        },
        n,
      );

  Map<DateAndTime, double> linearWeightedMovingAverage(int n) =>
      v(
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

