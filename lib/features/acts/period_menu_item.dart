import 'package:material_ui/material_ui.dart';
import 'package:mem/features/acts/line_chart/states.dart';

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
