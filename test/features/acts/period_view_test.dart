import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/acts/period_view.dart';

void main() {
  test('shortLabel', () {
    expect(Period.aDay.shortLabel, 'd');
    expect(Period.aWeek.shortLabel, 'w');
    expect(Period.aMonth.shortLabel, 'm');
    expect(Period.threeMonth.shortLabel, '3m');
    expect(Period.aYear.shortLabel, 'y');
    expect(Period.all.shortLabel, 'all');
  });

  test('icon', () {
    expect(Period.aDay.icon, Icons.calendar_view_day);
    expect(Period.aWeek.icon, Icons.calendar_view_week);
    expect(Period.aMonth.icon, Icons.calendar_view_month);
    expect(Period.threeMonth.icon, Icons.date_range);
    expect(Period.aYear.icon, Icons.calendar_today);
    expect(Period.all.icon, Icons.all_inclusive);
  });
}
