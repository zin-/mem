import 'package:flutter/material.dart';
import 'package:mem/components/date_and_time/date_and_time_period_view.dart';
import 'package:mem/core/act.dart';
import 'package:mem/core/mem.dart';

import 'editing_act_dialog.dart';

class ActListItemView extends ListTile {
  ActListItemView(
    BuildContext context,
    Act act, {
    // Act一覧の要素に対してMemがあったら名前を表示するという実装は合っているだろうか？
    SavedMemV2? mem,
    super.key,
  }) : super(
          title: DateAndTimePeriodTexts(act.period),
          subtitle: mem == null ? null : Text(mem.name),
          onLongPress: () {
            showDialog(
              context: context,
              builder: (context) => EditingActDialog(act),
            );
          },
        );
}
