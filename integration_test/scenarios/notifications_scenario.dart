import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/core/mem_notification.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';

import 'helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testNotificationsScenario();
}

const _scenarioName = "Notifications scenario";

void testNotificationsScenario() => group(
      ": $_scenarioName",
      () {
        const insertedMemName = "$_scenarioName - inserted - mem name";

        late final DatabaseAccessor dbA;
        int? insertedMemId;

        setUpAll(() async {
          dbA = await openTestDatabase(databaseDefinition);
        });
        setUp(() async {
          await clearAllTestDatabaseRows(databaseDefinition);

          insertedMemId = await dbA.insert(defTableMems, {
            defColMemsName.name: insertedMemName,
            defColMemsDoneAt.name: null,
            defColCreatedAt.name: zeroDate,
          });
          await dbA.insert(defTableMemNotifications, {
            defFkMemNotificationsMemId.name: insertedMemId,
            defColMemNotificationsTime.name: 0,
            defColMemNotificationsType.name: MemNotificationType.repeat.name,
            defColMemNotificationsMessage.name:
                "$_scenarioName - inserted - mem notification message",
            defColCreatedAt.name: zeroDate,
          });
        });
      },
    );
