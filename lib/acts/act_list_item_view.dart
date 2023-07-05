import 'package:flutter/material.dart';
import 'package:mem/acts/list_item/editing_act_dialog.dart';
import 'package:mem/components/date_and_time/date_and_time_period_view.dart';

import '../../core/act.dart';

class ActListItemView extends ListTile {
  final Act act;

  ActListItemView(BuildContext context, this.act, {super.key})
      : super(
          title: DateAndTimePeriodTexts(act.period),
          onLongPress: () {
            showDialog(
              context: context,
              builder: (context) => EditingActDialog(act),
            );
          },
        );
}
