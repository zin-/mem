import 'package:material_ui/material_ui.dart';
import 'package:mem/framework/date_and_time/period.dart';

class PeriodMenuItem extends PopupMenuItem<Period> {
  PeriodMenuItem({
    required Period period,
    required Period selected,
    super.onTap,
    super.key,
  }) : super(
          value: period,
          enabled: period != selected,
          child: Text(period.name),
        );
}
