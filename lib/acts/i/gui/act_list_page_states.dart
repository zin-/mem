import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mem/gui/list_value_state_notifier.dart';
import 'package:mem/logger/i/api.dart';

import '../../core/act.dart';
import '../../core/date_and_time_period.dart';

final actListProvider =
    StateNotifierProvider<ListValueStateNotifier<Act>, List<Act>?>(
  (ref) => v(
    {},
    () {
      final actList = ListValueStateNotifier<Act>(null);

      Future.delayed(
        const Duration(seconds: 1),
        () => List.generate(
          20,
          (index) => Act(
            DateAndTimePeriod.startNow(),
          ),
        ),
      ).then((value) => actList.updatedBy(value));

      return actList;
    },
  ),
);
