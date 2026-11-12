import 'package:material_ui/material_ui.dart';

extension TimeOfDayExt on TimeOfDay {
  static TimeOfDay fromSeconds(int seconds) {
    final hours = (seconds / 60 / 60).floor();
    return TimeOfDay(
      hour: hours,
      minute: ((seconds - hours * 60 * 60) / 60).floor(),
    );
  }
}
