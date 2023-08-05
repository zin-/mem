import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mem/acts/act_list_actions.dart';
import 'package:mem/acts/act_list_states.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/values/dimens.dart';

class ActLineChartPage extends ConsumerWidget {
  final int _memId;

  const ActLineChartPage(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          // TODO: divide
          final mem = ref.read(memDetailProvider(_memId)).mem;

          return Scaffold(
            appBar: AppBar(title: Text(mem.name)),
            body: Padding(
              padding: pagePadding,
              child: AsyncValueView(
                loadActList(_memId),
                (loaded) {
                  final actsSummary = ActsSummary(
                    ref
                        .watch(actListProvider(_memId))!
                        .where((element) => element.memId == _memId),
                  );

                  const yAxisTitles = AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                    ),
                  );
                  final min = actsSummary.min;
                  final max = actsSummary.max;

                  return LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        horizontalInterval:
                            max == min ? 1 : ((max - min) / 4).ceilToDouble(),
                      ),
                      minY: min > 0 ? min - 1 : 0,
                      maxY: max + 1,
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(),
                        leftTitles: yAxisTitles,
                        rightTitles: yAxisTitles,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: const Duration(days: 1)
                                .inMilliseconds
                                .toDouble(),
                            getTitlesWidget: (value, meta) {
                              final dateTime =
                                  DateTime.fromMillisecondsSinceEpoch(
                                value.toInt(),
                              );
                              if (value == meta.min ||
                                  value == meta.max ||
                                  dateTime.month == 1) {
                                return Text(
                                  DateFormat.yMd().format(
                                    dateTime,
                                  ),
                                );
                              } else if (dateTime.day == 1) {
                                return Text(DateFormat.Md().format(
                                  dateTime,
                                ));
                              } else if (dateTime.day == 5 ||
                                  dateTime.day == 10 ||
                                  dateTime.day == 15 ||
                                  dateTime.day == 20 ||
                                  dateTime.day == 25) {
                                return Text(DateFormat.d().format(
                                  dateTime,
                                ));
                              } else {
                                return const Text('');
                              }
                            },
                          ),
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots: actsSummary
                              .simpleMovingAverage(5)
                              .entries
                              .map(
                                (e) => FlSpot(
                                  e.key.millisecondsSinceEpoch.toDouble(),
                                  e.value,
                                ),
                              )
                              .toList(),
                          isCurved: true,
                          dotData: const FlDotData(show: false),
                          color: Colors.teal,
                        ),
                        LineChartBarData(
                          spots: actsSummary
                              .linearWeightedMovingAverage(5)
                              .entries
                              .map(
                                (e) => FlSpot(
                                  e.key.millisecondsSinceEpoch.toDouble(),
                                  e.value,
                                ),
                              )
                              .toList(),
                          isCurved: true,
                          dotData: const FlDotData(show: false),
                          color: Colors.tealAccent,
                        ),
                        LineChartBarData(
                          spots: actsSummary.groupedListByDate.entries
                              .map((e) => FlSpot(
                                    e.key.millisecondsSinceEpoch.toDouble(),
                                    e.value.length.toDouble(),
                                  ))
                              .toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
        _memId,
      );
}

class ActsSummary {
  final Iterable<Act> _acts;

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

  Map<DateAndTime, List<Act>> _groupListByDate() => v(
        () {
          final groupedListByDate = _acts.groupListsBy(
            (element) => DateAndTime.from(element.period.start!),
          );

          final fillElements = <MapEntry<DateAndTime, List<Act>>>[];
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
