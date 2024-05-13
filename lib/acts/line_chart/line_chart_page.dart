import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/actions.dart';
import 'package:mem/acts/acts_summary.dart';
import 'package:mem/acts/line_chart/line_chart_wrapper.dart';
import 'package:mem/acts/states.dart';
import 'package:mem/components/async_value_view.dart';
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
              ref.read(
                editingMemByMemIdProvider(_memId).select((value) => value.name),
              ),
            ),
          ),
          body: Padding(
            padding: defaultPadding,
            child: AsyncValueView(
              loadActList(_memId),
              (loaded) => LineChartWrapper(
                ActsSummary(
                  ref
                      .watch(actListProvider(_memId))
                      .where((element) => element.memId == _memId),
                ),
              ),
            ),
          ),
        ),
        {
          "_memId": _memId,
        },
      );
}
