import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/acts/act_repository.dart';
import 'package:mem/database/definition.dart';
import 'package:mem/framework/database/database_manager.dart';
import 'package:mem/logger/log_entity.dart';
import 'package:mem/logger/log_service.dart';
import 'package:mem/mems/mem_item_repository_v2.dart';
import 'package:mem/mems/mem_repository_v2.dart';
import 'package:mem/mems/mem_service.dart';
import 'framework/database.dart';
import 'scenarios/act_counter_scenario.dart';
import '_helpers.dart';
import 'database/_database_manager.dart';
import 'database/_indexed_database.dart';
import 'database/_sqlite_database.dart';
import 'repositories/_act_repository.dart';
import 'scenarios/edge_scenario.dart';
import 'scenarios/habit_scenario.dart';
import 'scenarios/memo_scenario.dart';
import 'repositories/_notification_repository.dart';
import 'scenarios/todo_scenario.dart';
import 'scenarios/act_scenario.dart';
import 'scenarios/task_scenario.dart';

const defaultDuration = Duration(seconds: 1);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const onCICD = bool.fromEnvironment('CICD', defaultValue: false);
  info({'onCICD': onCICD});
  LogService.initialize(Level.verbose, onCICD);

  // app_testではないので、分けた方が良いかも？
  group('Framework test', () {
    testDatabaseV2();
  });

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
    setUp(() {
      MemRepository.resetWith(null);
      MemItemRepository.resetWith(null);
      ActRepository.resetWith(null);

      MemService.reset(null);
    });

    testMemoScenario();
    testTodoScenario();
    testTaskScenario();
    testHabitScenario();

    testActScenario();

    testEdgeScenario();

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

      group('Act test', () {
        testActCounterConfigure();
      });
    });
  });
}
