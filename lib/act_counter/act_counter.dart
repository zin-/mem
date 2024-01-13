import 'package:collection/collection.dart';

import 'package:mem/core/act.dart';
import 'package:mem/core/date_and_time/date_and_time.dart';
import 'package:mem/core/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/repositories/mem.dart';

class ActCounter extends Entity {
  final SavedMem _mem;
  final Iterable<SavedAct> _acts;
  final int memId;
  final int? actCount;
  final DateTime? lastUpdatedAt;
  final String? name;

  ActCounter(this._mem, this._acts)
      : memId = _mem.id,
        name = _mem.name,
        actCount = _acts.length,
        lastUpdatedAt = (_acts
                .sorted(
                  (a, b) => (a.updatedAt ?? a.createdAt)
                      .compareTo(b.updatedAt ?? b.createdAt),
                )
                .lastOrNull)
            ?.period
            .end;

  Map<String, dynamic> widgetData() {
    final lastAct = _acts
        .sorted(
          (a, b) => (a.updatedAt ?? a.createdAt)
              .compareTo(b.updatedAt ?? b.createdAt),
        )
        .lastOrNull;

    return {
      'memName-${_mem.id}': _mem.name,
      'actCount-${_mem.id}': _acts.length,
      'lastUpdatedAtSeconds-${_mem.id}': lastAct == null
          ? null
          : (lastAct.period.end ?? lastAct.period.start!)
              .millisecondsSinceEpoch
              .toDouble(),
    };
  }

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

class InitializedActCounter extends ActCounter {
  final int homeWidgetId;

  InitializedActCounter(this.homeWidgetId, ActCounter actCounter)
      : super(actCounter._mem, actCounter._acts);

  @override
  Map<String, dynamic> widgetData() => super.widgetData()
    ..putIfAbsent(
      'memId-$homeWidgetId',
      () => _mem.id,
    );
}
