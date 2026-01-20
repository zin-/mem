import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/migrations/native_to_drift.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/factory.dart';

const _name = "Native to Drift tests";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group(_name, () {
    group("Migrations", () {
      test("Table mems.", () async {
        final nativeDatabaseAccessor =
            await DatabaseFactory.open(databaseDefinition);

        await nativeDatabaseAccessor.insert(defTableMems, {
          defColMemsName.name: "test",
          defColCreatedAt.name: DateTime.now(),
        });

        final driftDatabaseAccessor = DriftDatabaseAccessor();
        await migrateNativeToDrift(driftDatabaseAccessor.driftDatabase);
      });
    });
  });
}
