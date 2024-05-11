import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mem/logger/log.dart';
import 'package:mem/logger/log_service.dart';

import 'framework/framework_test.dart' as framework_tests;
import 'scenarios/edge_scenario.dart';
import 'scenarios/habit/scenarios.dart' as habit_scenarios;
import 'scenarios/memo/memo_test.dart' as memo_scenarios;
import 'scenarios/memo_scenario.dart';
import 'scenarios/notification_scenario.dart';
import 'scenarios/notifications_scenario.dart';
import 'scenarios/settings_scenario.dart' as settings_scenario;
import 'scenarios/task_scenario.dart';
import 'scenarios/todo_scenario.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const onCICD = bool.fromEnvironment('CICD', defaultValue: false);
  LogService.initialize(Level.verbose, onCICD);
  info({'onCICD': onCICD});

  // app_testではないので、分けた方が良いかも？
  framework_tests.main();

  group('Scenario test', () {
    memo_scenarios.main();
    habit_scenarios.main();

    testNotificationsScenario();

    testMemoScenario();
    testTodoScenario();
    testTaskScenario();

    settings_scenario.main();

    testNotificationScenario();
    testEdgeScenario();
  });
}
