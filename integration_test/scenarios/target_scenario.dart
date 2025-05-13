import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/acts/line_chart/states.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/framework/database/accessor.dart';

import 'helpers.dart';

const _scenarioName = "Target scenario";

void main() => group(_scenarioName, () {
      IntegrationTestWidgetsFlutterBinding.ensureInitialized();

      late final DatabaseAccessor dbA;
      setUpAll(() async {
        dbA = await openTestDatabase(databaseDefinition);
      });

      const insertedMemName = '$_scenarioName: inserted - mem name';
      setUp(() async {
        await clearAllTestDatabaseRows(databaseDefinition);

        await dbA.insert(
          defTableMems,
          {
            defColMemsName.name: insertedMemName,
            defColCreatedAt.name: zeroDate,
          },
        );
      });

      testWidgets("Show target.", (widgetTester) async {
        await runApplication();
        await widgetTester.pumpAndSettle();

        await widgetTester.tap(find.text(insertedMemName));
        await widgetTester.pumpAndSettle();

        expect(find.text(TargetType.equalTo.name), findsOneWidget);
        expect(find.text(TargetUnit.count.name), findsOneWidget);
        expect(find.text(Period.aDay.name), findsOneWidget);
      });
    });
