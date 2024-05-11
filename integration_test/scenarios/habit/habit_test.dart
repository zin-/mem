import 'package:flutter_test/flutter_test.dart';
import 'package:mem/logger/log.dart';
import 'package:mem/logger/log_service.dart';

import 'act_counter_scenario.dart' as act_counter_scenario;
import 'after_act_started_habit_scenario.dart'
    as after_act_started_habit_scenario;
import 'repeated_habit_scenario.dart' as repeated_habit_scenario;
import 'repeat_by_n_day_habit_scenario.dart' as repeat_by_n_day_habit_scenario;
import 'act_list_page_scenario.dart' as act_list_page_scenario;
import 'act_line_chart_page_scenario.dart' as act_line_chart_page_scenario;
import 'mem_list_page_scenario.dart' as mem_list_page_scenario;

const _name = "Habit scenario";

void main() => group(
      _name,
      () {
        LogService.initialize(
          Level.verbose,
          const bool.fromEnvironment('CICD', defaultValue: false),
        );

        act_list_page_scenario.main();
        act_line_chart_page_scenario.main();
        mem_list_page_scenario.main();

        act_counter_scenario.main();

        after_act_started_habit_scenario.main();
        repeat_by_n_day_habit_scenario.main();
        repeated_habit_scenario.main();
      },
    );
