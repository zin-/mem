import 'package:collection/collection.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mem/acts/acts_summary.dart';

class LineChartWrapper extends StatelessWidget {
  // もうちょい汎用的な型を作る？
  //  YAGNIに反するのでやらない
  //  将来的にはActTotalTimeByDateを作る #248
  //  この際にChart用の入力値を作ることになるので、それが汎用的な型になるはず
  final ActsSummary _actsSummary;

  const LineChartWrapper(this._actsSummary, {super.key});

  @override
  Widget build(BuildContext context) {
    const yAxisTitles = AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        interval: 1,
      ),
    );

    final titlesData = FlTitlesData(
      topTitles: const AxisTitles(),
      leftTitles: yAxisTitles,
      rightTitles: yAxisTitles,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: const Duration(days: 1).inMilliseconds.toDouble(),
          getTitlesWidget: (value, meta) {
            final dateTime = DateTime.fromMillisecondsSinceEpoch(
              value.toInt(),
            );

            return Text(
              (value == meta.min || value == meta.max || dateTime.month == 1
                          ? DateFormat.yMd()
                          : dateTime.day == 1
                              ? DateFormat.Md()
                              : dateTime.day == 5 ||
                                      dateTime.day == 10 ||
                                      dateTime.day == 15 ||
                                      dateTime.day == 20 ||
                                      dateTime.day == 25 ||
                                      dateTime.day == 30
                                  ? DateFormat.d()
                                  : null)
                      ?.format(dateTime) ??
                  "",
            );
          },
        ),
      ),
    );
    final actCount = LineChartBarData(
      spots: _actsSummary.groupedListByDate.entries
          .map((e) => FlSpot(
                e.key.millisecondsSinceEpoch.toDouble(),
                e.value.length.toDouble(),
              ))
          .toList(),
    );
    final sma5 = _actsSummary.simpleMovingAverage(5);
    final lwma5 = _actsSummary.linearWeightedMovingAverage(5);

    final min = _actsSummary.min;
    final max = [_actsSummary.max, sma5.values.max, lwma5.values.max].max;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: max == min ? 1 : ((max - min) / 4).ceilToDouble(),
        ),
        minY: min > 0 ? min - 1 : 0,
        maxY: max + 1,
        titlesData: titlesData,
        lineBarsData: [
          LineChartBarData(
            spots: sma5.entries
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
            spots: lwma5.entries
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
          actCount,
        ],
      ),
    );
  }
}
