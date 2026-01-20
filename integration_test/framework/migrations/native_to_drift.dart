import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/migrations/native_to_drift.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/logger/log_service.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/factory.dart';

const _name = "Native to Drift tests";

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    DatabaseFactory.onTest = true;
  });
  setUp(() async {
    final nativeDatabaseAccessor =
        await DatabaseFactory.open(databaseDefinition);
    for (var tableDefinition in databaseDefinition.tableDefinitions) {
      await nativeDatabaseAccessor.delete(tableDefinition);
    }

    final driftDatabaseAccessor = DriftDatabaseAccessor();
    for (var tableDefinition in databaseDefinition.tableDefinitions) {
      await driftDatabaseAccessor.delete(tableDefinition, null);
    }
  });

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

        final nativeMems = await nativeDatabaseAccessor.select(defTableMems);

        final driftMems = await driftDatabaseAccessor.select(defTableMems);

        expect(nativeMems.length, equals(driftMems.length));

        for (var i = 0; i < nativeMems.length; i++) {
          final nativeMem = nativeMems[i];
          final driftMem = driftMems[i];

          final driftMemMap = (driftMem as dynamic).toJson(
            serializer: drift.ValueSerializer.defaults(
              serializeDateTimeValuesAsString: true,
            ),
          ) as Map<String, dynamic>;

          expect(driftMemMap['id'], equals(nativeMem['id']));
          expect(driftMemMap['name'], equals(nativeMem['name']));

          void compareNullableDateTime(String key) {
            final nativeValue = nativeMem[key];
            final driftValue = driftMemMap[key];
            if (nativeValue == null) {
              expect(driftValue, isNull);
            } else {
              final nativeDateTime = nativeValue as DateTime;
              final nativeValueString = DateTime(
                nativeDateTime.year,
                nativeDateTime.month,
                nativeDateTime.day,
                nativeDateTime.hour,
                nativeDateTime.minute,
                nativeDateTime.second,
              ).toIso8601String();
              expect(driftValue, equals(nativeValueString));
            }
          }

          compareNullableDateTime('doneAt');
          compareNullableDateTime('notifyOn');
          compareNullableDateTime('notifyAt');
          compareNullableDateTime('endOn');
          compareNullableDateTime('endAt');
          compareNullableDateTime('createdAt');
          compareNullableDateTime('updatedAt');
          compareNullableDateTime('archivedAt');
        }
      });
    });
  });
}
