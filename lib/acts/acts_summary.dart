import 'package:collection/collection.dart';
import 'package:mem/acts/act.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/statistics/summary_statistics.dart';

class ActsSummary extends SummaryStatistics {
  ActsSummary(Iterable<Act> acts) : super(_groupListByDate(acts));

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
                (index) =>
                MapEntry(element.key.add(Duration(days: index + 1)), []),
          ));
        }
      }
    });
    groupedListByDate.addEntries(fillElements);

    return groupedListByDate.entries
        .sorted((a, b) => a.key.compareTo(b.key))
        .groupListsBy(
          (element) =>
      groupedListByDate.length > DateTime.daysPerWeek * 4 * 3
          ? element.key.year * 100 + element.key.month
          : groupedListByDate.length > DateTime.daysPerWeek * 4
          ? element.key.weekNumber
          : element.key,
    )
        .map(
          (key, value) =>
          MapEntry(
            value.first.key,
            value
                .map((e) => e.value)
                .flattened
                .toList(),
          ),
    );
  }

  @override
  Map<DateAndTime, List<Act>> get groupedListByDate =>
      super.groupedListByDate as Map<DateAndTime, List<Act>>;
}
