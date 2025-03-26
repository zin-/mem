import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/actions.dart';
import 'package:mem/acts/acts_summary.dart';
import 'package:mem/acts/line_chart/line_chart_wrapper.dart';
import 'package:mem/acts/line_chart/states.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/view/async_value_view.dart';
import 'package:mem/l10n/l10n.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/settings/preference/keys.dart';
import 'package:mem/settings/states.dart';
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

  @override
  Widget build(BuildContext context) => _ActLineChartPage(
        widget._memId,
        _period,
        (selected) => setState(() => _period = selected),
      );
}

class _ActLineChartPage extends ConsumerWidget {
  final int _memId;
  final Period _period;
  final void Function(Period selected) _onPeriodSelected;

  const _ActLineChartPage(
    this._memId,
    this._period,
    this._onPeriodSelected,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => AsyncValueView(
          loadActListProvider(_memId, _period),
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
            ),
            _period,
            _onPeriodSelected,
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

  const _ActLineChartScreen(
    this._memName,
    this._actsSummary,
    this._period,
    this._onPeriodSelected,
  );

  @override
  Widget build(BuildContext context) => v(
        () => Scaffold(
          appBar: AppBar(
            title: Text("$_memName : Count"),
            actions: [
              PopupMenuButton(
                itemBuilder: (context) => Period.values
                    .map(
                      (e) => PopupMenuItem(
                        enabled: e != _period,
                        onTap: () => _onPeriodSelected(e),
                        child: Text(e.name),
                      ),
                    )
                    .toList(growable: false),
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
                    child: Flex(
                      direction: Axis.horizontal,
                      spacing: 4.0,
                      children: [
                        Text("Min : "),
                        Text(_actsSummary.min.toString()),
                        Text("Max : "),
                        Text(_actsSummary.max.toString()),
                        Text("Avg : "),
                        Text(_actsSummary.average.toStringAsPrecision(2)),
                      ],
                    ),
                  ),
                  Expanded(child: LineChartWrapper(_actsSummary)),
                ],
              )),
        ),
        {
          '_memName': _memName,
          '_actsSummary': _actsSummary,
          '_period': _period,
        },
      );
}
