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
        () => Scaffold(
          appBar: AppBar(
            title: Text(
              "${ref.read(
                editingMemByMemIdProvider(_memId).select((v) => v.value.name),
              )} : Count",
            ),
            actions: AppBarActionsBuilder([]).build(context),
          ),
          body: Padding(
            padding: defaultPadding,
            child: AsyncValueView(
              loadActList(_memId),
              (loaded) {
                final actSummary = ActsSummary(ref
                    .watch(actListProvider(_memId))
                    .map((e) => e.value)
                    .where((element) => element.memId == _memId));

                return Flex(
                  direction: Axis.vertical,
                  children: [
                    Padding(
                      padding: defaultPadding,
                      child: Flex(
                        direction: Axis.horizontal,
                        spacing: 4.0,
                        children: [
                          Text("Min : "),
                          Text(actSummary.min.toString()),
                          Text("Max : "),
                          Text(actSummary.max.toString()),
                          Text("Avg : "),
                          Text(actSummary.average.toStringAsPrecision(2)),
                        ],
                      ),
                    ),
                    Expanded(child: LineChartWrapper(actSummary)),
                  ],
                );
              },
            ),
          ),
        ),
        {
          "_memId": _memId,
        },
      );
}
