import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/actions.dart';
import 'package:mem/acts/acts_summary.dart';
import 'package:mem/acts/line_chart/line_chart_wrapper.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/framework/view/app_bar_actions_builder.dart';
import 'package:mem/framework/view/async_value_view.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/values/dimens.dart';

class ActLineChartPage extends ConsumerWidget {
  final int _memId;

  const ActLineChartPage(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () => AsyncValueView(
          loadActList(_memId),
          (loaded) => _ActLineChartScreen(
            ref.read(
              editingMemByMemIdProvider(_memId).select((v) => v.value.name),
            ),
            ActsSummary(ref
                .watch(actListProvider(_memId))
                .map((e) => e.value)
                .where((element) => element.memId == _memId)),
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

  const _ActLineChartScreen(this._memName, this._actsSummary);

  @override
  Widget build(BuildContext context) => v(
        () => Scaffold(
          appBar: AppBar(
            title: Text("$_memName : Count"),
            actions: AppBarActionsBuilder([]).build(context),
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
        },
      );
}
