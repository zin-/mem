import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/logger/i/type.dart';
import 'package:mem/main.dart';

import 'scenarios/act_counter_scenario.dart';
import '_helpers.dart';
import 'database/_database_manager.dart';
import 'database/_indexed_database.dart';
import 'database/_sqlite_database.dart';
import 'repositories/_log_repository.dart';
import 'repositories/_act_repository.dart';
import 'scenarios/_edge_scenario.dart';
import 'scenarios/_memo_scenario.dart';
import 'repositories/_notification_repository.dart';
import 'scenarios/todo_scenario.dart';
import 'scenarios/act_scenario.dart';
import 'scenarios/task_scenario.dart';

const defaultDuration = Duration(seconds: 1);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testLogRepository();

  initializeLogger(Level.error);

  group('Database test', () {
    testSqliteDatabase();
    testIndexedDatabase();

    testDatabaseManager();
  });

  group('Repository test', () {
    testNotificationRepository();
    testActRepository();
  });

  group('Scenario test', () {
    testActScenario();

    group('V1', () {
      setUpAll(() async {
        await DatabaseManager(onTest: true).open(databaseDefinition);
      });
      setUp(() async {
        await clearDatabase();
      });
      tearDownAll(() async {
        await DatabaseManager().delete(databaseDefinition.name);
      });

      testMemoScenario();
      testTodoScenario();
      testTaskScenario();

      testEdgeScenario();

      group('Act test', () {
        testActCounterConfigure();
      });
    });
  });
}
