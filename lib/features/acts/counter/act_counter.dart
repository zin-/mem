import 'package:collection/collection.dart';
import 'package:mem/features/acts/counter/home_widget.dart';

import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/mems/mem_entity.dart';

class ActCounter implements HomeWidget {
  @override
  String get methodChannelName => 'zin.playground.mem/act_counter';

  @override
  String get initializeMethodName => 'initialize';

  @override
  String get widgetProviderName => 'ActCounterProvider';

  final int memId;
  final String? name;
  final int? actCount;
  final DateTime? updatedAt;

  ActCounter(this.memId, this.name, this.actCount, this.updatedAt);

  ActCounter.from(
    SavedMemEntityV2 savedMem,
    Iterable<SavedActEntity> savedActs,
  )   : memId = savedMem.id,
        name = savedMem.value.name,
        actCount = savedActs.length,
        updatedAt = savedActs
                .sorted(
                  (a, b) => (a.updatedAt ?? a.createdAt)
                      .compareTo(b.updatedAt ?? b.createdAt),
                )
                .lastOrNull
                ?.value
                .period
                ?.end ??
            savedActs
                .sorted(
                  (a, b) => (a.updatedAt ?? a.createdAt)
                      .compareTo(b.updatedAt ?? b.createdAt),
                )
                .lastOrNull
                ?.value
                .period
                ?.start;

  static DateAndTimePeriod period(DateAndTime startDate) {
    int startHour = 5;
    int datePeriod = 1;
    DateAndTime start = startDate.hour < startHour
        ? DateAndTime(
            startDate.year,
            startDate.month,
            startDate.day,
            startHour,
            0,
          ).subtract(Duration(days: datePeriod))
        : DateAndTime(
            startDate.year,
            startDate.month,
            startDate.day,
            startHour,
            0,
          );
    return DateAndTimePeriod(
      start: start,
      end: start.add(Duration(days: datePeriod)),
    );
  }
}
