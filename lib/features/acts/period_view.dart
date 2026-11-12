import 'package:material_ui/material_ui.dart';
import 'package:mem/features/acts/line_chart/states.dart';

extension PeriodView on Period {
  String get shortLabel => switch (this) {
        Period.aDay => 'd',
        Period.aWeek => 'w',
        Period.aMonth => 'm',
        Period.threeMonth => '3m',
        Period.aYear => 'y',
        Period.all => 'all',
      };

  IconData get icon => switch (this) {
        Period.aDay => Icons.calendar_view_day,
        Period.aWeek => Icons.calendar_view_week,
        Period.aMonth => Icons.calendar_view_month,
        Period.threeMonth => Icons.date_range,
        Period.aYear => Icons.calendar_today,
        Period.all => Icons.all_inclusive,
      };
}
