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

    final actCount = _actsSummary.groupedListByDate.entries
        .map((e) => FlSpot(
              e.key.millisecondsSinceEpoch.toDouble(),
              e.value,
            ))
        .toList(growable: false);
    final sma5 = _actsSummary.simpleMovingAverage(5);
    final lwma5 = _actsSummary.linearWeightedMovingAverage(5);

    final min = _actsSummary.min;
    final max = [
      _actsSummary.max,
      sma5.values.isEmpty ? 0 : sma5.values.max,
      lwma5.values.isEmpty ? 0 : lwma5.values.max,
    ].max;

    final interval = Duration(
            days: _actsSummary.groupedListByDate.entries.length > 1
                ? _actsSummary.groupedListByDate.entries.last.key
                    .difference(_actsSummary.groupedListByDate.entries
                        .elementAt(
                            _actsSummary.groupedListByDate.entries.length - 2)
                        .key)
                    .inDays
                : 1)
        .inMilliseconds
        .toDouble();

    final titlesData = FlTitlesData(
      topTitles: const AxisTitles(),
      leftTitles: yAxisTitles,
      rightTitles: yAxisTitles,
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          interval: interval,
          getTitlesWidget: (value, meta) {
            final dateTime = DateTime.fromMillisecondsSinceEpoch(
              value.toInt(),
            );

            DateFormat? formatter;
            if (value == meta.min || value == meta.max) {
              formatter = DateFormat.yMd();
            } else if (meta.axisPosition < meta.parentAxisSize * 0.1 ||
                meta.parentAxisSize * 0.9 < meta.axisPosition) {
              formatter = null;
            } else if (dateTime.day == 1) {
              formatter = DateFormat.Md();
            } else if (dateTime.day == 10 || dateTime.day == 20) {
              formatter = DateFormat.d();
            }

            return Text(
              formatter?.format(dateTime) ?? "",
            );
          },
        ),
      ),
    );

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
                    double.parse(e.value.toStringAsPrecision(3)),
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
                    double.parse(e.value.toStringAsPrecision(3)),
                  ),
                )
                .toList(),
            isCurved: true,
            dotData: const FlDotData(show: false),
            color: Colors.tealAccent,
          ),
          LineChartBarData(
            spots: actCount,
          ),
        ],
        lineTouchData: LineTouchData(
          enabled: true,
        ),
      ),
    );
  }
}
