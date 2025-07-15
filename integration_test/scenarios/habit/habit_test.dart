import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/logger/log.dart';
import 'package:mem/features/logger/log_service.dart';

import 'act_counter_scenario.dart' as act_counter_scenario;
import 'after_act_started_habit_scenario.dart'
    as after_act_started_habit_scenario;
import 'repeated_habit_scenario.dart' as repeated_habit_scenario;
import 'repeat_by_day_of_week_scenario.dart' as repeat_by_day_of_week_scenario;
import 'repeat_by_n_day_habit_scenario.dart' as repeat_by_n_day_habit_scenario;
import 'act_list_page_scenario.dart' as act_list_page_scenario;
import 'act_line_chart_page_scenario.dart' as act_line_chart_page_scenario;
import 'mem_list_page_scenario.dart' as mem_list_page_scenario;
import 'mem_relations_scenarios.dart' as mem_relations_scenarios;

const _name = "Habit scenario";

void main() => group(
      _name,
      () {
        LogService(
          level: Level.verbose,
          enableSimpleLog:
              const bool.fromEnvironment('CICD', defaultValue: false),
        );

        act_list_page_scenario.main();
        act_line_chart_page_scenario.main();
        mem_list_page_scenario.main();

        act_counter_scenario.main();

        after_act_started_habit_scenario.main();
        repeat_by_n_day_habit_scenario.main();
        if (defaultTargetPlatform == TargetPlatform.android) {
          repeat_by_day_of_week_scenario.main();
        }
        repeated_habit_scenario.main();
        mem_relations_scenarios.main();
      },
    );
