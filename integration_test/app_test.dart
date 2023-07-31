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
import 'framework/database_factory.dart';
import 'scenarios/act_counter_scenario.dart';
import '_helpers.dart';
import 'database/_database_manager.dart';
import 'database/_indexed_database.dart';
import 'database/_sqlite_database.dart';
import 'scenarios/edge_scenario.dart';
import 'scenarios/habit_scenario.dart';
import 'scenarios/memo_scenario.dart';
import 'scenarios/notification_scenario.dart';
import 'scenarios/todo_scenario.dart';
import 'scenarios/act_scenario.dart';
import 'scenarios/task_scenario.dart';

const defaultDuration = Duration(seconds: 1);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const onCICD = bool.fromEnvironment('CICD', defaultValue: false);
  LogService.initialize(Level.verbose, onCICD);
  info({'onCICD': onCICD});

  // app_testではないので、分けた方が良いかも？
  group('Framework test', () {
    testDatabaseFactoryV2();
  });

  group('Database test', () {
    testSqliteDatabase();
    testIndexedDatabase();

    testDatabaseManager();
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

    testNotificationScenario();

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
