import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/acts_summary.dart';
import 'package:mem/features/acts/line_chart/line_chart_wrapper.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
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

  void _selectPeriod(Period period) => setState(() {
        _period = period;
        _periodOffset = 0;
      });

  void _goPreviousPeriod() => setState(() => _periodOffset--);

  void _goNextPeriod() => setState(() {
        if (_periodOffset < 0) {
          _periodOffset++;
        }
      });

  @override
  Widget build(BuildContext context) => v(
        () {
          final selectedPeriod = _period.toPeriod(
            DateAndTime.now(),
            ref.watch(preferenceProvider(startOfDayKey)),
            offset: _periodOffset,
          );

          return AsyncValueView(
            loadActListProvider(widget.memId, _period),
            (_) => _buildScaffold(context, selectedPeriod),
          );
        },
        {
          'memId': widget.memId,
        },
      );

  Widget _buildScaffold(
    BuildContext context,
    DateAndTimePeriod? selectedPeriod,
  ) {
    final memName = ref.read(
      editingMemByMemIdProvider(widget.memId).select((v) => v.value.name),
    );
    final actsSummary = ActsSummary(
      _actsInPeriod(selectedPeriod),
      _aggregationType,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('$memName : ${_aggregationType.name}'),
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => <PopupMenuEntry>[
              ...AggregationType.values.map(
                (e) => PopupMenuItem(
                  enabled: e != _aggregationType,
                  onTap: () => setState(() => _aggregationType = e),
                  child: Text(e.name),
                ),
              ),
              const PopupMenuDivider(),
              ...Period.values.map(
                (e) => PopupMenuItem(
                  enabled: e != _period,
                  onTap: () => _selectPeriod(e),
                  child: Text(e.name),
                ),
              ),
            ],
            tooltip: buildL10n(context).timePeriod,
            padding: defaultPadding,
            icon: const Icon(Icons.more_vert),
          ),
        ],
      ),
      body: Padding(
        padding: defaultPadding,
        child: Flex(
          direction: Axis.vertical,
          children: [
            if (_period != Period.all)
              _PeriodNavigation(
                periodLabel: selectedPeriod!.formatCompactRange(
                  MaterialLocalizations.of(context),
                ),
                canGoNext: _periodOffset < 0,
                onPrevious: _goPreviousPeriod,
                onNext: _goNextPeriod,
              ),
            _SummaryStats(actsSummary, _aggregationType.format),
            Expanded(
              child: LineChartWrapper(
                actsSummary,
                _aggregationType.format,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Iterable<Act> _actsInPeriod(DateAndTimePeriod? selectedPeriod) => ref
      .watch(actListProvider(widget.memId).select(
        (value) => value.where((e) =>
            e.value.memId == widget.memId &&
            (_period == Period.all ||
                e.value.period?.compareTo(selectedPeriod!) == 1)),
      ))
      .map((e) => e.value);
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
            spacing: 4.0,
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
