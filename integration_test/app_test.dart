import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mem/logger/log.dart';
import 'package:mem/logger/log_service.dart';

import 'framework/database_accessor.dart';
import 'framework/database_factory.dart';
import 'scenarios/act_counter_scenario.dart';
import 'scenarios/act_scenario.dart';
import 'scenarios/edge_scenario.dart';
import 'scenarios/habit/after_act_started_habit_scenario.dart';
import 'scenarios/habit/repeat_by_n_day_habit_scenario.dart';
import 'scenarios/habit/repeated_habit_scenario.dart';
import 'scenarios/memo/mem_list_scenario.dart';
import 'scenarios/memo/memo_detail_scenario.dart';
import 'scenarios/memo_scenario.dart';
import 'scenarios/notification_scenario.dart';
import 'scenarios/notifications_scenario.dart';
import 'scenarios/settings_scenario.dart';
import 'scenarios/task_scenario.dart';
import 'scenarios/todo_scenario.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const onCICD = bool.fromEnvironment('CICD', defaultValue: false);
  LogService.initialize(Level.verbose, onCICD);
  info({'onCICD': onCICD});

  // app_testではないので、分けた方が良いかも？
  group('Framework test', () {
    testDatabaseFactory();
    testDatabaseAccessor();
  });

  group('Scenario test', () {
    testMemoListScenario();
    testMemoDetailScenario();

    testRepeatedHabitScenario();
    testRepeatByNDayHabitScenario();
    testAfterActStartedHabitScenario();

    testNotificationsScenario();

    testMemoScenario();
    testTodoScenario();
    testTaskScenario();

    testActScenario();

    testSettingsScenario();

    testNotificationScenario();
    testActCounterConfigure();

    testEdgeScenario();
  });
}
