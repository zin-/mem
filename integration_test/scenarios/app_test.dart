import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mem/logger/log.dart';
import 'package:mem/logger/log_service.dart';

import 'edge_scenario.dart';
import 'memo/memo_test.dart' as memo_test;
import 'habit/habit_test.dart' as habit_test;
import 'notification_scenario.dart';
import 'task_scenario.dart';
import 'todo_scenario.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const onCICD = bool.fromEnvironment('CICD', defaultValue: false);
  LogService.initialize(
    level: Level.verbose,
    enableSimpleLog: onCICD,
  );
  info({'onCICD': onCICD});

  group('Scenario test', () {
    memo_test.main();
    habit_test.main();

    testTodoScenario();
    testTaskScenario();

    testNotificationScenario();
    testEdgeScenario();
  });
}
