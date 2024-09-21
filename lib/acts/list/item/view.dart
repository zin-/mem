import 'package:flutter/material.dart';
import 'package:mem/components/date_and_time/date_and_time_period_view.dart';
import 'package:mem/core/act.dart';
import 'package:mem/logger/log_service.dart';

import 'editing_act_dialog.dart';

class ActListItemView extends StatelessWidget {
  final SavedAct _act;

  // Act一覧の要素に対してMemがあったら名前を表示するという実装は合っているだろうか？
  final String? _memName;

  const ActListItemView(this._act, this._memName, {super.key});

  @override
  Widget build(BuildContext context) => v(
        () {
          return ListTile(
            title: DateAndTimePeriodTexts(
              _act.period,
              showDate: false,
            ),
            subtitle: _memName == null ? null : Text(_memName),
            onLongPress: () {
              showDialog(
                context: context,
                builder: (context) => EditingActDialog(_act.id),
              );
            },
          );
        },
        {"_act": _act, "_memName": _memName},
      );
}
