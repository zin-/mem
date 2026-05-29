import 'package:flutter/material.dart';
import 'package:mem/framework/date_and_time/date_and_time_period_view.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/generated/l10n/app_localizations.dart';
import 'package:mem/l10n/l10n.dart';

import 'editing_act_dialog.dart';

class ActListItemView extends StatelessWidget {
  final SavedActEntityV1 _act;

  // Act一覧の要素に対してMemがあったら名前を表示するという実装は合っているだろうか？
  final String? _memName;

  const ActListItemView(this._act, this._memName, {super.key});

  @override
  Widget build(BuildContext context) => v(
        () {
          final l10n = buildL10n(context);
          return ListTile(
            title: DateAndTimePeriodTexts(
              _act.value.period!,
              showDate: false,
            ),
            subtitle: _buildSubtitle(l10n),
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

  Widget? _buildSubtitle(AppLocalizations l10n) {
    final skippedLabel =
        _act.value.isSkipped ? Text(l10n.actSkippedLabel) : null;
    if (_memName == null) {
      return skippedLabel;
    }
    if (skippedLabel == null) {
      return Text(_memName);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_memName),
        skippedLabel,
      ],
    );
  }
}
