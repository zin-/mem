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
import 'package:mem/values/constants.dart';
import 'package:mem/values/dimens.dart';

class ActLineChartPage extends StatefulWidget {
  final int _memId;

  const ActLineChartPage({
    super.key,
    required int memId,
  }) : _memId = memId;

  @override
  State<StatefulWidget> createState() => ActLineChartPageState();
}

class ActLineChartPageState extends State<ActLineChartPage> {
  Period _period = Period.aWeek;
  AggregationType _aggregationType = AggregationType.count;

  @override
  Widget build(BuildContext context) => _ActLineChartPage(
        widget._memId,
        _period,
        (selected) => setState(() => _period = selected),
        _aggregationType,
        (selected) => setState(() => _aggregationType = selected),
      );
}

// FIXME 先にConsumerの処理をして、子にStatefulを持つべきでは？
class _ActLineChartPage extends ConsumerWidget {
  final int _memId;
  final Period _period;
  final void Function(Period selected) _onPeriodSelected;
  final AggregationType _aggregationType;
  final void Function(AggregationType aggregationType)
      _onAggregationTypeSelected;

  const _ActLineChartPage(
    this._memId,
    this._period,
    this._onPeriodSelected,
    this._aggregationType,
    this._onAggregationTypeSelected,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => AsyncValueView(
          loadActListV2Provider(_memId, _period),
          (loaded) => _ActLineChartScreen(
            ref.read(
              editingMemByMemIdProvider(_memId).select((v) => v.value.name),
            ),
            ActsSummary(
              ref
                  .watch(actListProvider(_memId).select(
                    (value) {
                      final period = _period.toPeriod(
                        DateAndTime.now(),
                        ref.watch(preferencesProvider).value?[startOfDayKey] ??
                            defaultStartOfDay,
                      );
                      return value.where((e) =>
                          e.value.memId == _memId &&
                          (_period == Period.all ||
                              e.value.period?.compareTo(period!) == 1));
                    },
                  ))
                  .map((e) => e.value),
              _aggregationType,
            ),
            _period,
            _onPeriodSelected,
            _aggregationType,
            _onAggregationTypeSelected,
          ),
        ),
        {
          '_memId': _memId,
        },
      );
}

class _ActLineChartScreen extends StatelessWidget {
  final String _memName;
  final ActsSummary _actsSummary;
  final Period _period;
  final void Function(Period selected) _onPeriodSelected;
  final AggregationType _aggregationType;
  final void Function(AggregationType aggregationType)
      _onAggregationTypeSelected;

  const _ActLineChartScreen(
    this._memName,
    this._actsSummary,
    this._period,
    this._onPeriodSelected,
    this._aggregationType,
    this._onAggregationTypeSelected,
  );

  @override
  Widget build(BuildContext context) => v(
        () => Scaffold(
          appBar: AppBar(
            title: Text("$_memName : ${_aggregationType.name}"),
            actions: [
              PopupMenuButton(
                itemBuilder: (context) => <PopupMenuEntry>[
                  ...AggregationType.values.map(
                    (e) => PopupMenuItem(
                      enabled: e != _aggregationType,
                      onTap: () => _onAggregationTypeSelected(e),
                      child: Text(e.name),
                    ),
                  ),
                  PopupMenuDivider(),
                  ...Period.values.map(
                    (e) => PopupMenuItem(
                      enabled: e != _period,
                      onTap: () => _onPeriodSelected(e),
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
                  Padding(
                    padding: defaultPadding,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Flex(
                        direction: Axis.horizontal,
                        spacing: 4.0,
                        children: [
                          Text("Min : "),
                          Text(_formatValue(_actsSummary.min)),
                          Text("Max : "),
                          Text(_formatValue(_actsSummary.max)),
                          Text("Avg : "),
                          Text(_formatValue(_actsSummary.average)),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                      child: LineChartWrapper(
                    _actsSummary,
                    _formatValue,
                  )),
                ],
              )),
        ),
        {
          '_memName': _memName,
          '_actsSummary': _actsSummary,
          '_period': _period,
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
