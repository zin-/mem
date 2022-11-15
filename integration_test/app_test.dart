import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/logger/i/api.dart';
import 'package:mem/logger/i/type.dart';

import 'act/_act_list_page.dart';
import 'database/_database_manager.dart';
import 'database/_indexed_database.dart';
import 'database/_sqlite_database.dart';
import 'repositories/_database_tuple_repository.dart';
import 'repositories/_log_repository.dart';
import 'scenarios/_edge_scenario.dart';
import 'scenarios/_memo_scenario.dart';
import 'repositories/_notification_repository.dart';
import 'scenarios/_todo_scenario.dart';

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
    testDatabaseTupleRepository();
    testNotificationRepository();
  });

  DatabaseManager(onTest: true);

  group('Scenario test', () {
    testMemoScenario();
    testTodoScenario();

    testEdgeScenario();
  });

  group('Act test', () {
    testActListPage();
  });
}
