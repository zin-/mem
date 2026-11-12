import 'package:material_ui/material_ui.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_amount.dart';
import 'package:mem/features/acts/list/duration.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/values/colors.dart';
import 'package:mem/values/dimens.dart';

import 'act_list_group.dart';

class ActListSubHeader extends StatelessWidget {
  final _subHeaderTextStyle = const TextStyle(color: secondaryGreyColor);

  final ActListGroup _group;
  final List<Act> _acts;

  const ActListSubHeader(
    this._group,
    this._acts, {
    super.key,
  });

  @override
  Widget build(BuildContext context) => v(
        () {
          final amount = ActAmount.of(_acts);
          return Container(
            padding: defaultPadding,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    _group.label(MaterialLocalizations.of(context)),
                    style: _subHeaderTextStyle,
                  ),
                ),
                Text(
                  amount.count.toString(),
                  style: _subHeaderTextStyle,
                ),
                Text(
                  amount.recorded.format(),
                  style: _subHeaderTextStyle,
                ),
              ],
            ),
          );
        },
        {"_group": _group},
      );
}
