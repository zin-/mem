import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/migrations/native_to_drift.dart';
import 'package:mem/framework/database/accessor.dart';

const _name = "Native to Drift test";

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group(_name, () {
    group("migration", () {
      test("mems table.", () async {
        final driftDatabaseAccessor = DriftDatabaseAccessor();

        await migrateNativeToDrift(driftDatabaseAccessor.driftDatabase);
      });
    });
  });
}
