import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/definition.dart';
import 'package:mem/databases/migrations/native_to_drift.dart';
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/definition/column/foreign_key_definition.dart';
import 'package:mem/framework/database/factory.dart';

const _name = "Native to Drift tests";

void compareNullableDateTime(
  Map<String, dynamic> nativeMem,
  Map<String, dynamic> driftMemMap,
  String key,
) {
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    DatabaseFactory.onTest = true;
  });
  setUp(() async {
    final nativeDatabaseAccessor =
        await DatabaseFactory.open(databaseDefinition);
    final tablesToDelete = databaseDefinition.tableDefinitions.toList();
    tablesToDelete.sort((a, b) {
      final aHasFk = a.columnDefinitions.any((c) => c is ForeignKeyDefinition);
      final bHasFk = b.columnDefinitions.any((c) => c is ForeignKeyDefinition);
      if (aHasFk && !bHasFk) return -1;
      if (!aHasFk && bHasFk) return 1;
      return 0;
    });
    for (var tableDefinition in tablesToDelete) {
      try {
        await nativeDatabaseAccessor.delete(tableDefinition);
      } catch (e) {
        // Ignore foreign key constraint errors during cleanup
      }
    }

    final driftDatabaseAccessor = DriftDatabaseAccessor();
    for (var tableDefinition in tablesToDelete) {
      try {
        await driftDatabaseAccessor.delete(tableDefinition, null);
      } catch (e) {
        // Ignore foreign key constraint errors during cleanup
      }
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

          compareNullableDateTime(nativeMem, driftMemMap, 'doneAt');
          compareNullableDateTime(nativeMem, driftMemMap, 'notifyOn');
          compareNullableDateTime(nativeMem, driftMemMap, 'notifyAt');
          compareNullableDateTime(nativeMem, driftMemMap, 'endOn');
          compareNullableDateTime(nativeMem, driftMemMap, 'endAt');
          compareNullableDateTime(nativeMem, driftMemMap, 'createdAt');
          compareNullableDateTime(nativeMem, driftMemMap, 'updatedAt');
          compareNullableDateTime(nativeMem, driftMemMap, 'archivedAt');
        }
      });

      test("Table mem_items.", () async {
        final nativeDatabaseAccessor =
            await DatabaseFactory.open(databaseDefinition);

        final memId = await nativeDatabaseAccessor.insert(defTableMems, {
          defColMemsName.name: "test",
          defColCreatedAt.name: DateTime.now(),
        });

        await nativeDatabaseAccessor.insert(defTableMemItems, {
          defColMemItemsType.name: "memo",
          defColMemItemsValue.name: "test_value",
          defFkMemItemsMemId.name: memId,
          defColCreatedAt.name: DateTime.now(),
        });

        final driftDatabaseAccessor = DriftDatabaseAccessor();
        await migrateNativeToDrift(driftDatabaseAccessor.driftDatabase);

        final nativeMemItems =
            await nativeDatabaseAccessor.select(defTableMemItems);
        final driftMemItems =
            await driftDatabaseAccessor.select(defTableMemItems);

        expect(nativeMemItems.length, equals(driftMemItems.length));

        for (var i = 0; i < nativeMemItems.length; i++) {
          final nativeMemItem = nativeMemItems[i];
          final driftMemItem = driftMemItems[i];

          final driftMemItemMap = (driftMemItem as dynamic).toJson(
            serializer: drift.ValueSerializer.defaults(
              serializeDateTimeValuesAsString: true,
            ),
          ) as Map<String, dynamic>;

          expect(driftMemItemMap['id'], equals(nativeMemItem['id']));
          expect(driftMemItemMap['type'], equals(nativeMemItem['type']));
          expect(driftMemItemMap['value'], equals(nativeMemItem['value']));
          expect(driftMemItemMap['memId'],
              equals(nativeMemItem[defFkMemItemsMemId.name]));

          compareNullableDateTime(nativeMemItem, driftMemItemMap, 'createdAt');
          compareNullableDateTime(nativeMemItem, driftMemItemMap, 'updatedAt');
          compareNullableDateTime(nativeMemItem, driftMemItemMap, 'archivedAt');
        }
      });

      test("Table acts.", () async {
        final nativeDatabaseAccessor =
            await DatabaseFactory.open(databaseDefinition);

        final memId = await nativeDatabaseAccessor.insert(defTableMems, {
          defColMemsName.name: "test",
          defColCreatedAt.name: DateTime.now(),
        });

        await nativeDatabaseAccessor.insert(defTableActs, {
          defColActsStart.name: DateTime.now(),
          defColActsStartIsAllDay.name: true,
          defColActsEnd.name: DateTime.now(),
          defColActsEndIsAllDay.name: false,
          defColActsPausedAt.name: DateTime.now(),
          defFkActsMemId.name: memId,
          defColCreatedAt.name: DateTime.now(),
        });

        final driftDatabaseAccessor = DriftDatabaseAccessor();
        await migrateNativeToDrift(driftDatabaseAccessor.driftDatabase);

        final nativeActs = await nativeDatabaseAccessor.select(defTableActs);
        final driftActs = await driftDatabaseAccessor.select(defTableActs);

        expect(nativeActs.length, equals(driftActs.length));

        for (var i = 0; i < nativeActs.length; i++) {
          final nativeAct = nativeActs[i];
          final driftAct = driftActs[i];

          final driftActMap = (driftAct as dynamic).toJson(
            serializer: drift.ValueSerializer.defaults(
              serializeDateTimeValuesAsString: true,
            ),
          ) as Map<String, dynamic>;

          expect(driftActMap['id'], equals(nativeAct['id']));
          expect(driftActMap['memId'], equals(nativeAct[defFkActsMemId.name]));

          final nativeStartIsAllDay = nativeAct[defColActsStartIsAllDay.name];
          final driftStartIsAllDay = driftActMap['startIsAllDay'];
          if (nativeStartIsAllDay == null) {
            expect(driftStartIsAllDay, isNull);
            compareNullableDateTime(nativeAct, driftActMap, 'start');
          } else {
            expect(driftStartIsAllDay, equals(nativeStartIsAllDay));
            if (nativeStartIsAllDay == true) {
              final nativeStart = nativeAct[defColActsStart.name];
              final driftStart = driftActMap['start'];
              if (nativeStart == null) {
                expect(driftStart, isNull);
              } else {
                final nativeDateTime = nativeStart as DateTime;
                final expectedString = DateTime(
                  nativeDateTime.year,
                  nativeDateTime.month,
                  nativeDateTime.day,
                ).toIso8601String();
                expect(driftStart, equals(expectedString));
              }
            } else {
              compareNullableDateTime(nativeAct, driftActMap, 'start');
            }
          }

          final nativeEndIsAllDay = nativeAct[defColActsEndIsAllDay.name];
          final driftEndIsAllDay = driftActMap['endIsAllDay'];
          if (nativeEndIsAllDay == null) {
            expect(driftEndIsAllDay, isNull);
            compareNullableDateTime(nativeAct, driftActMap, 'end');
          } else {
            expect(driftEndIsAllDay, equals(nativeEndIsAllDay));
            if (nativeEndIsAllDay == true) {
              final nativeEnd = nativeAct[defColActsEnd.name];
              final driftEnd = driftActMap['end'];
              if (nativeEnd == null) {
                expect(driftEnd, isNull);
              } else {
                final nativeDateTime = nativeEnd as DateTime;
                final expectedString = DateTime(
                  nativeDateTime.year,
                  nativeDateTime.month,
                  nativeDateTime.day,
                ).toIso8601String();
                expect(driftEnd, equals(expectedString));
              }
            } else {
              compareNullableDateTime(nativeAct, driftActMap, 'end');
            }
          }

          compareNullableDateTime(nativeAct, driftActMap, 'pausedAt');

          compareNullableDateTime(nativeAct, driftActMap, 'createdAt');
          compareNullableDateTime(nativeAct, driftActMap, 'updatedAt');
          compareNullableDateTime(nativeAct, driftActMap, 'archivedAt');
        }
      });

      test("Table mem_repeated_notifications.", () async {
        final nativeDatabaseAccessor =
            await DatabaseFactory.open(databaseDefinition);

        final memId = await nativeDatabaseAccessor.insert(defTableMems, {
          defColMemsName.name: "test",
          defColCreatedAt.name: DateTime.now(),
        });

        await nativeDatabaseAccessor.insert(defTableMemNotifications, {
          defColMemNotificationsTime.name: 3600,
          defColMemNotificationsType.name: "repeat",
          defColMemNotificationsMessage.name: "test_message",
          defFkMemNotificationsMemId.name: memId,
          defColCreatedAt.name: DateTime.now(),
        });

        final driftDatabaseAccessor = DriftDatabaseAccessor();
        await migrateNativeToDrift(driftDatabaseAccessor.driftDatabase);

        final nativeMemNotifications =
            await nativeDatabaseAccessor.select(defTableMemNotifications);
        final driftMemNotifications =
            await driftDatabaseAccessor.select(defTableMemNotifications);

        expect(nativeMemNotifications.length,
            equals(driftMemNotifications.length));

        for (var i = 0; i < nativeMemNotifications.length; i++) {
          final nativeMemNotification = nativeMemNotifications[i];
          final driftMemNotification = driftMemNotifications[i];

          final driftMemNotificationMap =
              (driftMemNotification as dynamic).toJson(
            serializer: drift.ValueSerializer.defaults(
              serializeDateTimeValuesAsString: true,
            ),
          ) as Map<String, dynamic>;

          expect(driftMemNotificationMap['id'],
              equals(nativeMemNotification['id']));
          expect(
            driftMemNotificationMap['timeOfDaySeconds'],
            equals(nativeMemNotification[defColMemNotificationsTime.name]),
          );
          expect(
            driftMemNotificationMap['type'],
            equals(nativeMemNotification[defColMemNotificationsType.name]),
          );
          expect(
            driftMemNotificationMap['message'],
            equals(nativeMemNotification[defColMemNotificationsMessage.name]),
          );
          expect(
            driftMemNotificationMap['memId'],
            equals(nativeMemNotification[defFkMemNotificationsMemId.name]),
          );

          compareNullableDateTime(
              nativeMemNotification, driftMemNotificationMap, 'createdAt');
          compareNullableDateTime(
              nativeMemNotification, driftMemNotificationMap, 'updatedAt');
          compareNullableDateTime(
              nativeMemNotification, driftMemNotificationMap, 'archivedAt');
        }
      });

      test("Table targets.", () async {
        final nativeDatabaseAccessor =
            await DatabaseFactory.open(databaseDefinition);

        final memId = await nativeDatabaseAccessor.insert(defTableMems, {
          defColMemsName.name: "test",
          defColCreatedAt.name: DateTime.now(),
        });

        await nativeDatabaseAccessor.insert(defTableTargets, {
          defColTargetType.name: "equalTo",
          defColTargetUnit.name: "count",
          defColTargetValue.name: 100,
          defColTargetPeriod.name: "aDay",
          defFkTargetMemId.name: memId,
          defColCreatedAt.name: DateTime.now(),
        });

        final driftDatabaseAccessor = DriftDatabaseAccessor();
        await migrateNativeToDrift(driftDatabaseAccessor.driftDatabase);

        final nativeTargets =
            await nativeDatabaseAccessor.select(defTableTargets);
        final driftTargets =
            await driftDatabaseAccessor.select(defTableTargets);

        expect(nativeTargets.length, equals(driftTargets.length));

        for (var i = 0; i < nativeTargets.length; i++) {
          final nativeTarget = nativeTargets[i];
          final driftTarget = driftTargets[i];

          final driftTargetMap = (driftTarget as dynamic).toJson(
            serializer: drift.ValueSerializer.defaults(
              serializeDateTimeValuesAsString: true,
            ),
          ) as Map<String, dynamic>;

          expect(driftTargetMap['id'], equals(nativeTarget['id']));
          expect(driftTargetMap['type'],
              equals(nativeTarget[defColTargetType.name]));
          expect(driftTargetMap['unit'],
              equals(nativeTarget[defColTargetUnit.name]));
          expect(driftTargetMap['value'],
              equals(nativeTarget[defColTargetValue.name]));
          expect(driftTargetMap['period'],
              equals(nativeTarget[defColTargetPeriod.name]));
          expect(driftTargetMap['memId'],
              equals(nativeTarget[defFkTargetMemId.name]));

          compareNullableDateTime(nativeTarget, driftTargetMap, 'createdAt');
          compareNullableDateTime(nativeTarget, driftTargetMap, 'updatedAt');
          compareNullableDateTime(nativeTarget, driftTargetMap, 'archivedAt');
        }
      });

      test("Table mem_relations.", () async {
        final nativeDatabaseAccessor =
            await DatabaseFactory.open(databaseDefinition);

        final sourceMemId = await nativeDatabaseAccessor.insert(defTableMems, {
          defColMemsName.name: "source_test",
          defColCreatedAt.name: DateTime.now(),
        });

        final targetMemId = await nativeDatabaseAccessor.insert(defTableMems, {
          defColMemsName.name: "target_test",
          defColCreatedAt.name: DateTime.now(),
        });

        await nativeDatabaseAccessor.insert(defTableMemRelations, {
          defFkMemRelationsSourceMemId.name: sourceMemId,
          defFkMemRelationsTargetMemId.name: targetMemId,
          defColMemRelationsType.name: "prePost",
          defColMemRelationsValue.name: 10,
          defColCreatedAt.name: DateTime.now(),
        });

        final driftDatabaseAccessor = DriftDatabaseAccessor();
        await migrateNativeToDrift(driftDatabaseAccessor.driftDatabase);

        final nativeMemRelations =
            await nativeDatabaseAccessor.select(defTableMemRelations);
        final driftMemRelations =
            await driftDatabaseAccessor.select(defTableMemRelations);

        expect(nativeMemRelations.length, equals(driftMemRelations.length));

        for (var i = 0; i < nativeMemRelations.length; i++) {
          final nativeMemRelation = nativeMemRelations[i];
          final driftMemRelation = driftMemRelations[i];

          final driftMemRelationMap = (driftMemRelation as dynamic).toJson(
            serializer: drift.ValueSerializer.defaults(
              serializeDateTimeValuesAsString: true,
            ),
          ) as Map<String, dynamic>;

          expect(driftMemRelationMap['id'], equals(nativeMemRelation['id']));
          expect(
            driftMemRelationMap['sourceMemId'],
            equals(nativeMemRelation[defFkMemRelationsSourceMemId.name]),
          );
          expect(
            driftMemRelationMap['targetMemId'],
            equals(nativeMemRelation[defFkMemRelationsTargetMemId.name]),
          );
          expect(
            driftMemRelationMap['type'],
            equals(nativeMemRelation[defColMemRelationsType.name]),
          );

          final nativeValue = nativeMemRelation[defColMemRelationsValue.name];
          final driftValue = driftMemRelationMap['value'];
          if (nativeValue == null) {
            expect(driftValue, isNull);
          } else {
            expect(driftValue, equals(nativeValue));
          }

          compareNullableDateTime(
              nativeMemRelation, driftMemRelationMap, 'createdAt');
          compareNullableDateTime(
              nativeMemRelation, driftMemRelationMap, 'updatedAt');
          compareNullableDateTime(
              nativeMemRelation, driftMemRelationMap, 'archivedAt');
        }
      });
    });
  });
}
