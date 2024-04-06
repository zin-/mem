import 'package:flutter_test/flutter_test.dart';

import 'act_counter_scenario.dart' as act_counter_scenario;
import 'act_scenario.dart' as act_scenario;
import 'after_act_started_habit_scenario.dart'
    as after_act_started_habit_scenario;
import 'repeated_habit_scenario.dart' as repeated_habit_scenario;
import 'repeat_by_n_day_habit_scenario.dart' as repeat_by_n_day_habit_scenario;

const _name = "Habit scenario";

void main() => group(
      _name,
      () {
        act_scenario.main();

        act_counter_scenario.main();

        after_act_started_habit_scenario.main();
        repeat_by_n_day_habit_scenario.main();
        repeated_habit_scenario.main();
      },
    );
