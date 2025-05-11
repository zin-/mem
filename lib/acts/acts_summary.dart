import 'package:collection/collection.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/statistics/summary_statistics.dart';

enum AggregationType {
  count,
  sum,
}

class ActsSummary extends SummaryStatistics {
  final Map<DateAndTime, List<Act>> _groupedListByDate;
  final AggregationType _aggregationType;

  ActsSummary(Iterable<Act> acts, this._aggregationType)
      : _groupedListByDate = _groupListByDate(acts);

  @override
  Map<DateAndTime, List<Act>> get groupedListByDate => _groupedListByDate;

  @override
  double getValue(List<dynamic> items) {
    final acts = items as List<Act>;
    switch (_aggregationType) {
      case AggregationType.count:
        return acts.length.toDouble();
      case AggregationType.sum:
        return acts
            .map((act) => act.period?.duration.inSeconds ?? 0)
            .fold(0, (sum, duration) => sum + duration)
            .toDouble();
    }
  }

  static Map<DateAndTime, List<Act>> _groupListByDate(Iterable<Act> acts) {
    final groupedListByDate = acts
        .where((e) => e.period?.start != null)
        .groupListsBy((e) => DateAndTime.from(e.period!.start!));

    final fillElements = <MapEntry<DateAndTime, List<Act>>>[];
    groupedListByDate.entries.forEachIndexed((index, element) {
      if (index != 0) {
        final diffInDays = groupedListByDate.entries
            .elementAt(index - 1)
            .key
            .difference(element.key)
            .inDays;
        if (diffInDays != 1) {
          fillElements.addAll(Iterable.generate(
            diffInDays - 1,
            (index) => MapEntry(element.key.add(Duration(days: index + 1)), []),
          ));
        }
      }
    });
    groupedListByDate.addEntries(fillElements);

    return groupedListByDate.entries
        .sorted((a, b) => a.key.compareTo(b.key))
        .groupListsBy(
          (element) => groupedListByDate.length > DateTime.daysPerWeek * 4 * 3
              ? element.key.year * 100 + element.key.month
              : groupedListByDate.length > DateTime.daysPerWeek * 4
                  ? element.key.weekNumber
                  : element.key,
        )
        .map(
          (key, value) => MapEntry(
            value.first.key,
            value.map((e) => e.value).flattened.toList(),
          ),
        );
  }
}
