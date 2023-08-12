import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/acts/acts_summary.dart';
import 'package:mem/acts/line_chart/line_chart_wrapper.dart';
import 'package:mem/components/async_value_view.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/detail/states.dart';
import 'package:mem/values/dimens.dart';

import '../actions.dart';
import '../states.dart';

class ActLineChartPage extends ConsumerWidget {
  final int _memId;

  const ActLineChartPage(this._memId, {super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => v(
        () {
          final mem = ref.read(memDetailProvider(_memId)).mem;

          return Scaffold(
            appBar: AppBar(title: Text(mem.name)),
            body: Padding(
              padding: pagePadding,
              child: AsyncValueView(
                loadActList(_memId),
                (loaded) => LineChartWrapper(
                  ActsSummary(
                    ref
                        .watch(actListProvider(_memId))!
                        .where((element) => element.memId == _memId),
                  ),
                ),
              ),
            ),
          );
        },
        _memId,
      );
}
