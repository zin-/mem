import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/acts_summary.dart';
import 'package:mem/features/acts/line_chart/chart_vertical_drag.dart';
import 'package:mem/features/acts/line_chart/line_chart_wrapper.dart';
import 'package:mem/framework/date_and_time/period.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/date_and_time/date_and_time_period_view.dart';
import 'package:mem/framework/view/async_value_view.dart';
import 'package:mem/values/dimens.dart';

class LineChartPeriod extends ConsumerWidget {
  final int memId;
  final Period period;
  final int offset;
  final AggregationType aggregationType;
  final TimeOfDay startOfDay;
  final PageController? pageController;

  const LineChartPeriod({
    super.key,
    required this.memId,
    required this.period,
    required this.offset,
    required this.aggregationType,
    required this.startOfDay,
    this.pageController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Iterable<Act> actsIn(DateAndTimePeriod? selectedPeriod) => ref
        .watch(actListProvider(memId).select(
          (value) => value.where((e) {
            if (selectedPeriod is! WithStartAndEnd) {
              return true;
            }
            final start = e.value.period?.start;
            return start != null && selectedPeriod.includesStart(start);
          }),
        ))
        .map((e) => e.value);

    final selectedPeriod = period.toPeriod(
      DateAndTime.now(),
      startOfDay,
      offset: offset,
    );

    return AsyncValueView(
      loadActListProvider(memId, period, offset),
      (_) {
        final actsSummary = ActsSummary(
          actsIn(selectedPeriod),
          aggregationType,
          period: selectedPeriod,
          startOfDay: startOfDay,
        );
        final chart = LineChartWrapper(
          actsSummary,
          aggregationType.format,
        );
        final paging = pageController;

        return Flex(
          direction: Axis.vertical,
          children: [
            if (selectedPeriod is WithStartAndEnd)
              Text(
                selectedPeriod.formatCompactRange(
                  MaterialLocalizations.of(context),
                ),
                textAlign: TextAlign.center,
              ),
            _SummaryStats(actsSummary, aggregationType.format),
            Expanded(
              child: paging == null
                  ? chart
                  : ChartVerticalDrag(
                      controller: paging,
                      child: chart,
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SummaryStats extends StatelessWidget {
  final ActsSummary _actsSummary;
  final String Function(double) _formatValue;

  const _SummaryStats(this._actsSummary, this._formatValue);

  @override
  Widget build(BuildContext context) => Padding(
        padding: defaultPadding,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Flex(
            direction: Axis.horizontal,
            spacing: defaultComponentPadding,
            children: [
              const Text('Min : '),
              Text(_formatValue(_actsSummary.min)),
              const Text('Max : '),
              Text(_formatValue(_actsSummary.max)),
              const Text('Avg : '),
              Text(_formatValue(_actsSummary.average)),
            ],
          ),
        ),
      );
}
