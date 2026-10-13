import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/acts_summary.dart';
import 'package:mem/features/acts/line_chart/line_chart_wrapper.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/view/async_value_view.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/mems/detail/states.dart';
import 'package:mem/features/settings/preference/keys.dart';
import 'package:mem/features/settings/states.dart';
import 'package:mem/values/dimens.dart';

class ActLineChartPage extends ConsumerStatefulWidget {
  final int memId;

  const ActLineChartPage({
    super.key,
    required this.memId,
  });

  @override
  ConsumerState<ActLineChartPage> createState() => _ActLineChartPageState();
}

class _ActLineChartPageState extends ConsumerState<ActLineChartPage> {
  Period _period = Period.aWeek;
  int _periodOffset = 0;
  AggregationType _aggregationType = AggregationType.count;

  @override
  Widget build(BuildContext context) => v(
        () {
          final startOfDay = ref.watch(preferenceProvider(startOfDayKey));
          final selectedPeriod = _period.toPeriod(
            DateAndTime.now(),
            startOfDay,
            offset: _periodOffset,
          );

          return AsyncValueView(
            loadActListProvider(widget.memId, _period),
            (_) {
              final actsSummary = ActsSummary(
                ref
                    .watch(actListProvider(widget.memId).select(
                      (value) => value.where((e) =>
                          e.value.memId == widget.memId &&
                          (_period == Period.all ||
                              e.value.period?.compareTo(selectedPeriod!) ==
                                  1)),
                    ))
                    .map((e) => e.value),
                _aggregationType,
              );

              return Scaffold(
                appBar: AppBar(
                  title: Text(
                    "${ref.read(editingMemByMemIdProvider(widget.memId).select((v) => v.value.name))} : ${_aggregationType.name}",
                  ),
                  actions: [
                    PopupMenuButton(
                      itemBuilder: (context) => <PopupMenuEntry>[
                        ...AggregationType.values.map(
                          (e) => PopupMenuItem(
                            enabled: e != _aggregationType,
                            onTap: () =>
                                setState(() => _aggregationType = e),
                            child: Text(e.name),
                          ),
                        ),
                        PopupMenuDivider(),
                        ...Period.values.map(
                          (e) => PopupMenuItem(
                            enabled: e != _period,
                            onTap: () => setState(() {
                              _period = e;
                              _periodOffset = 0;
                            }),
                            child: Text(e.name),
                          ),
                        ),
                      ].toList(growable: false),
                      tooltip: buildL10n(context).timePeriod,
                      padding: defaultPadding,
                      icon: Icon(Icons.more_vert),
                    )
                  ],
                ),
                body: Padding(
                  padding: defaultPadding,
                  child: Flex(
                    direction: Axis.vertical,
                    children: [
                      if (_period != Period.all)
                        _PeriodNavigation(
                          periodLabel: _period.formatRange(
                            MaterialLocalizations.of(context),
                            selectedPeriod!,
                          ),
                          canGoNext: _periodOffset < 0,
                          onPrevious: () => setState(() => _periodOffset--),
                          onNext: () => setState(() {
                            if (_periodOffset < 0) {
                              _periodOffset++;
                            }
                          }),
                        ),
                      Padding(
                        padding: defaultPadding,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Flex(
                            direction: Axis.horizontal,
                            spacing: 4.0,
                            children: [
                              Text("Min : "),
                              Text(_formatValue(actsSummary.min)),
                              Text("Max : "),
                              Text(_formatValue(actsSummary.max)),
                              Text("Avg : "),
                              Text(_formatValue(actsSummary.average)),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        child: LineChartWrapper(
                          actsSummary,
                          _formatValue,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        {
          'memId': widget.memId,
        },
      );

  String _formatValue(double value) {
    switch (_aggregationType) {
      case AggregationType.count:
        return value.toStringAsFixed(1);
      case AggregationType.sum:
        final hours = (value / 3600).floor();
        final minutes = ((value % 3600) / 60).floor();
        final seconds = (value % 60).floor();
        return '${hours}h ${minutes}m ${seconds}s';
    }
  }
}

class _PeriodNavigation extends StatelessWidget {
  final String periodLabel;
  final bool canGoNext;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  const _PeriodNavigation({
    required this.periodLabel,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) => Flex(
        direction: Axis.horizontal,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Text(
              periodLabel,
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            onPressed: canGoNext ? onNext : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      );
}
