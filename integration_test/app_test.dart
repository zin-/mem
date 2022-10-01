import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/logger.dart';
import 'package:mem/database/database_manager.dart';

import 'database/_database_manager.dart';
import 'database/_indexed_database.dart';
import 'database/_sqlite_database.dart';
import 'repositories/_database_tuple_repository.dart';
import 'scenarios/_edge_scenario.dart';
import 'scenarios/_memo_scenario.dart';
import 'repositories/_notification_repository.dart';
import 'scenarios/_todo_scenario.dart';

const defaultDuration = Duration(seconds: 1);

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  Logger(level: Level.verbose);
  DatabaseManager(onTest: true);

  group('Database test', () {
    testSqliteDatabase();
    testIndexedDatabase();

    testDatabaseManager();
  });

  group('Repository test', () {
    testDatabaseTupleRepository();
    testNotificationRepository();
  });

  testMemoScenario();
  testTodoScenario();

  testEdgeScenario();
}
