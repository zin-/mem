import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Mem, MemItem, Act, Target;
import 'package:mem/databases/table_definitions/acts.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/databases/table_definitions/mem_items.dart';
import 'package:mem/databases/table_definitions/mem_notifications.dart';
import 'package:mem/databases/table_definitions/mem_relations.dart';
import 'package:mem/databases/table_definitions/mems.dart';
import 'package:mem/features/targets/target_table.dart';
import 'package:mem/features/acts/act.dart';
import 'package:mem/features/acts/act_entity.dart';
import 'package:mem/features/acts/act_repository.dart';
import 'package:mem/features/acts/line_chart/states.dart';
import 'package:mem/features/mem_items/mem_item.dart';
import 'package:mem/features/mem_items/mem_item_entity.dart';
import 'package:mem/features/mem_items/mem_item_repository.dart';
import 'package:mem/features/mem_notifications/mem_notification.dart';
import 'package:mem/features/mem_notifications/mem_notification_entity.dart';
import 'package:mem/features/mem_notifications/mem_notification_repository.dart';
import 'package:mem/features/mem_relations/mem_relation.dart';
import 'package:mem/features/mem_relations/mem_relation_entity.dart';
import 'package:mem/features/mem_relations/mem_relation_repository.dart';
import 'package:mem/features/mems/mem.dart';
import 'package:mem/features/mems/mem_entity.dart';
import 'package:mem/features/mems/mem_repository.dart';
import 'package:mem/features/targets/target.dart';
import 'package:mem/features/targets/target_entity.dart';
import 'package:mem/features/targets/target_repository.dart';
import 'package:mem/databases/migrations/native_to_drift.dart';
import 'package:mem/framework/database/accessor.dart';
import 'package:mem/framework/database/factory.dart';
import 'package:mem/framework/singleton.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

const _name = "Native to Drift test";

void main() => group(
      _name,
      () {
        setUpAll(() {
          DatabaseFactory.onTest = true;
          setOnTest(true);
        });

        setUp(() async {
          await DatabaseTupleRepository.close();

          if (Singleton.exists<DriftDatabaseAccessor>()) {
            final driftAccessor = DriftDatabaseAccessor();
            await driftAccessor.close();
          }
          DriftDatabaseAccessor.reset();

          final nativeDbPath =
              await DatabaseFactory.buildDatabasePath('mem.db');
          await DatabaseFactory
              // ignore: deprecated_member_use_from_same_package
              .nativeFactory
              .deleteDatabase(nativeDbPath);

          final dbFolder = await getApplicationDocumentsDirectory();
          final driftDbPath = path.join(dbFolder.path, 'test_mem_drift.db');
          final driftDbFile = File(driftDbPath);
          if (await driftDbFile.exists()) {
            try {
              await driftDbFile.delete(recursive: false);
            } catch (e) {
              // ファイルが使用中の場合は無視
            }
          }

          final driftDbWalPath =
              path.join(dbFolder.path, 'test_mem_drift.db-wal');
          final driftDbWalFile = File(driftDbWalPath);
          if (await driftDbWalFile.exists()) {
            try {
              await driftDbWalFile.delete(recursive: false);
            } catch (e) {
              // ファイルが使用中の場合は無視
            }
          }

          final driftDbShmPath =
              path.join(dbFolder.path, 'test_mem_drift.db-shm');
          final driftDbShmFile = File(driftDbShmPath);
          if (await driftDbShmFile.exists()) {
            try {
              await driftDbShmFile.delete(recursive: false);
            } catch (e) {
              // ファイルが使用中の場合は無視
            }
          }
        });

        tearDownAll(() {
          DatabaseFactory.onTest = false;
          setOnTest(false);
        });

        test(
          'migrates mems data from native to drift database using migrateNativeToDrift',
          () async {
            final now = DateTime.now();
            final createdAt = now.subtract(const Duration(days: 1));

            final mem = MemEntity(
              Mem(
                null,
                'Test Mem',
                null,
                null,
              ),
            );
            final savedMem =
                await MemRepository().receive(mem, createdAt: createdAt);

            expect(savedMem.id, isNotNull);
            expect(savedMem.value.name, 'Test Mem');

            if (Singleton.exists<DriftDatabaseAccessor>()) {
              final existingAccessor = DriftDatabaseAccessor();
              await existingAccessor.close();
            }
            DriftDatabaseAccessor.reset();

            final dbFolder = await getApplicationDocumentsDirectory();
            final driftDbPath = path.join(dbFolder.path, 'test_mem_drift.db');
            final driftDbFile = File(driftDbPath);
            if (await driftDbFile.exists()) {
              try {
                await driftDbFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final driftDbWalPath =
                path.join(dbFolder.path, 'test_mem_drift.db-wal');
            final driftDbWalFile = File(driftDbWalPath);
            if (await driftDbWalFile.exists()) {
              try {
                await driftDbWalFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final driftDbShmPath =
                path.join(dbFolder.path, 'test_mem_drift.db-shm');
            final driftDbShmFile = File(driftDbShmPath);
            if (await driftDbShmFile.exists()) {
              try {
                await driftDbShmFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final driftDatabase = AppDatabase();

            final driftMemsBeforeMigration =
                await driftDatabase.select(driftDatabase.mems).get();

            if (driftMemsBeforeMigration.isEmpty) {
              await driftDatabase.customStatement('PRAGMA foreign_keys = ON');
              await driftDatabase.customStatement(
                  'CREATE TABLE IF NOT EXISTS mems (id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, name TEXT NOT NULL, doneAt INTEGER, notifyOn INTEGER, notifyAt INTEGER, endOn INTEGER, endAt INTEGER, createdAt INTEGER NOT NULL, updatedAt INTEGER, archivedAt INTEGER)');

              final driftMemsBefore =
                  await driftDatabase.select(driftDatabase.mems).get();
              expect(driftMemsBefore.length, 0);

              await migrateNativeToDrift(driftDatabase);
            }

            final driftMems =
                await driftDatabase.select(driftDatabase.mems).get();

            expect(driftMems.length, 1);

            final driftMem = driftMems.first;
            expect(driftMem.id, savedMem.id);
            expect(driftMem.name, savedMem.value.name);
            expect(driftMem.doneAt, savedMem.value.doneAt);
            expect(driftMem.createdAt.millisecondsSinceEpoch ~/ 1000,
                savedMem.createdAt.millisecondsSinceEpoch ~/ 1000);
            expect(driftMem.updatedAt, savedMem.updatedAt);
            expect(driftMem.archivedAt, savedMem.archivedAt);

            await driftDatabase.close();
          },
        );

        test(
          'migrates mem_items data from native to drift database using migrateNativeToDrift',
          () async {
            final now = DateTime.now();
            final createdAt = now.subtract(const Duration(days: 1));

            final mem = MemEntity(
              Mem(
                null,
                'Test Mem for MemItem',
                null,
                null,
              ),
            );
            final savedMem =
                await MemRepository().receive(mem, createdAt: createdAt);

            final memItem = MemItemEntity(
              MemItem(savedMem.id, MemItemType.memo, 'Test memo'),
            );
            final savedMemItem = await MemItemRepository()
                .receive(memItem, createdAt: createdAt);

            expect(savedMemItem.id, isNotNull);
            expect(savedMemItem.value.memId, savedMem.id);
            expect(savedMemItem.value.type, MemItemType.memo);
            expect(savedMemItem.value.value, 'Test memo');

            if (Singleton.exists<DriftDatabaseAccessor>()) {
              final existingAccessor = DriftDatabaseAccessor();
              await existingAccessor.close();
            }
            DriftDatabaseAccessor.reset();

            final testDbFolder = await getApplicationDocumentsDirectory();
            final testDriftDbPath =
                path.join(testDbFolder.path, 'test_mem_drift.db');
            final testDriftDbFile = File(testDriftDbPath);
            if (await testDriftDbFile.exists()) {
              try {
                await testDriftDbFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final testDriftDbWalPath =
                path.join(testDbFolder.path, 'test_mem_drift.db-wal');
            final testDriftDbWalFile = File(testDriftDbWalPath);
            if (await testDriftDbWalFile.exists()) {
              try {
                await testDriftDbWalFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final testDriftDbShmPath =
                path.join(testDbFolder.path, 'test_mem_drift.db-shm');
            final testDriftDbShmFile = File(testDriftDbShmPath);
            if (await testDriftDbShmFile.exists()) {
              try {
                await testDriftDbShmFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final driftDatabase = AppDatabase();

            final driftMemItemsBeforeMigration =
                await driftDatabase.select(driftDatabase.memItems).get();

            if (driftMemItemsBeforeMigration.isEmpty) {
              await driftDatabase.customStatement('PRAGMA foreign_keys = ON');
              await driftDatabase
                  .customStatement(defTableMems.buildCreateTableSql());
              await driftDatabase
                  .customStatement(defTableMemItems.buildCreateTableSql());

              final driftMemItemsBefore =
                  await driftDatabase.select(driftDatabase.memItems).get();
              expect(driftMemItemsBefore.length, 0);

              await migrateNativeToDrift(driftDatabase);
            }

            final driftMemItems =
                await driftDatabase.select(driftDatabase.memItems).get();

            expect(driftMemItems.length, 1);

            final driftMemItem = driftMemItems.first;
            expect(driftMemItem.id, savedMemItem.id);
            expect(driftMemItem.memId, savedMemItem.value.memId);
            expect(driftMemItem.type, savedMemItem.value.type.name);
            expect(driftMemItem.value, savedMemItem.value.value);
            expect(driftMemItem.createdAt.millisecondsSinceEpoch ~/ 1000,
                savedMemItem.createdAt.millisecondsSinceEpoch ~/ 1000);
            expect(driftMemItem.updatedAt, savedMemItem.updatedAt);
            expect(driftMemItem.archivedAt, savedMemItem.archivedAt);

            await driftDatabase.close();
          },
        );

        test(
          'migrates acts data from native to drift database using migrateNativeToDrift',
          () async {
            final now = DateTime.now();
            final createdAt = now.subtract(const Duration(days: 1));

            final mem = MemEntity(
              Mem(
                null,
                'Test Mem for Act',
                null,
                null,
              ),
            );
            final savedMem =
                await MemRepository().receive(mem, createdAt: createdAt);

            final act = ActEntity(
              Act.by(
                savedMem.id,
                startWhen:
                    DateAndTime.from(now.subtract(const Duration(hours: 2))),
                endWhen:
                    DateAndTime.from(now.subtract(const Duration(hours: 1))),
              ),
            );
            final savedAct =
                await ActRepository().receive(act, createdAt: createdAt);

            expect(savedAct.id, isNotNull);
            expect(savedAct.value.memId, savedMem.id);

            if (Singleton.exists<DriftDatabaseAccessor>()) {
              final existingAccessor = DriftDatabaseAccessor();
              await existingAccessor.close();
            }
            DriftDatabaseAccessor.reset();

            final testDbFolder = await getApplicationDocumentsDirectory();
            final testDriftDbPath =
                path.join(testDbFolder.path, 'test_mem_drift.db');
            final testDriftDbFile = File(testDriftDbPath);
            if (await testDriftDbFile.exists()) {
              try {
                await testDriftDbFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final testDriftDbWalPath =
                path.join(testDbFolder.path, 'test_mem_drift.db-wal');
            final testDriftDbWalFile = File(testDriftDbWalPath);
            if (await testDriftDbWalFile.exists()) {
              try {
                await testDriftDbWalFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final testDriftDbShmPath =
                path.join(testDbFolder.path, 'test_mem_drift.db-shm');
            final testDriftDbShmFile = File(testDriftDbShmPath);
            if (await testDriftDbShmFile.exists()) {
              try {
                await testDriftDbShmFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final driftDatabase = AppDatabase();

            final driftActsBeforeMigration =
                await driftDatabase.select(driftDatabase.acts).get();

            if (driftActsBeforeMigration.isEmpty) {
              await driftDatabase.customStatement('PRAGMA foreign_keys = ON');
              await driftDatabase
                  .customStatement(defTableMems.buildCreateTableSql());
              await driftDatabase
                  .customStatement(defTableActs.buildCreateTableSql());

              final driftActsBefore =
                  await driftDatabase.select(driftDatabase.acts).get();
              expect(driftActsBefore.length, 0);

              await migrateNativeToDrift(driftDatabase);
            }

            final driftActs =
                await driftDatabase.select(driftDatabase.acts).get();

            expect(driftActs.length, 1);

            final driftAct = driftActs.first;
            expect(driftAct.id, savedAct.id);
            expect(driftAct.memId, savedAct.value.memId);
            expect(driftAct.start, savedAct.value.period?.start);
            expect(
                driftAct.startIsAllDay, savedAct.value.period?.start?.isAllDay);
            expect(driftAct.end, savedAct.value.period?.end);
            expect(driftAct.endIsAllDay, savedAct.value.period?.end?.isAllDay);
            expect(driftAct.createdAt.millisecondsSinceEpoch ~/ 1000,
                savedAct.createdAt.millisecondsSinceEpoch ~/ 1000);
            expect(driftAct.updatedAt, savedAct.updatedAt);
            expect(driftAct.archivedAt, savedAct.archivedAt);

            await driftDatabase.close();
          },
        );

        test(
          'migrates mem_notifications data from native to drift database using migrateNativeToDrift',
          () async {
            final now = DateTime.now();
            final createdAt = now.subtract(const Duration(days: 1));

            final mem = MemEntity(
              Mem(
                null,
                'Test Mem for Notification',
                null,
                null,
              ),
            );
            final savedMem =
                await MemRepository().receive(mem, createdAt: createdAt);

            final notification = MemNotificationEntity(
              MemNotification.by(
                savedMem.id,
                MemNotificationType.repeat,
                const Duration(hours: 9).inSeconds,
                'Test notification',
              ),
            );
            final savedNotification = await MemNotificationRepository()
                .receive(notification, createdAt: createdAt);

            expect(savedNotification.id, isNotNull);
            expect(savedNotification.value.memId, savedMem.id);
            expect(savedNotification.value.type, MemNotificationType.repeat);
            expect(savedNotification.value.time,
                const Duration(hours: 9).inSeconds);
            expect(savedNotification.value.message, 'Test notification');

            if (Singleton.exists<DriftDatabaseAccessor>()) {
              final existingAccessor = DriftDatabaseAccessor();
              await existingAccessor.close();
            }
            DriftDatabaseAccessor.reset();

            final testDbFolder = await getApplicationDocumentsDirectory();
            final testDriftDbPath =
                path.join(testDbFolder.path, 'test_mem_drift.db');
            final testDriftDbFile = File(testDriftDbPath);
            if (await testDriftDbFile.exists()) {
              try {
                await testDriftDbFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final testDriftDbWalPath =
                path.join(testDbFolder.path, 'test_mem_drift.db-wal');
            final testDriftDbWalFile = File(testDriftDbWalPath);
            if (await testDriftDbWalFile.exists()) {
              try {
                await testDriftDbWalFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final testDriftDbShmPath =
                path.join(testDbFolder.path, 'test_mem_drift.db-shm');
            final testDriftDbShmFile = File(testDriftDbShmPath);
            if (await testDriftDbShmFile.exists()) {
              try {
                await testDriftDbShmFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final driftDatabase = AppDatabase();

            final driftNotificationsBeforeMigration = await driftDatabase
                .select(driftDatabase.memRepeatedNotifications)
                .get();

            if (driftNotificationsBeforeMigration.isEmpty) {
              await driftDatabase.customStatement('PRAGMA foreign_keys = ON');
              await driftDatabase
                  .customStatement(defTableMems.buildCreateTableSql());
              await driftDatabase.customStatement(
                  defTableMemNotifications.buildCreateTableSql());

              final driftNotificationsBefore = await driftDatabase
                  .select(driftDatabase.memRepeatedNotifications)
                  .get();
              expect(driftNotificationsBefore.length, 0);

              await migrateNativeToDrift(driftDatabase);
            }

            final driftNotifications = await driftDatabase
                .select(driftDatabase.memRepeatedNotifications)
                .get();

            expect(driftNotifications.length, 1);

            final driftNotification = driftNotifications.first;
            expect(driftNotification.id, savedNotification.id);
            expect(driftNotification.memId, savedNotification.value.memId);
            expect(driftNotification.type, savedNotification.value.type.name);
            expect(driftNotification.timeOfDaySeconds,
                savedNotification.value.time);
            expect(driftNotification.message, savedNotification.value.message);
            expect(driftNotification.createdAt.millisecondsSinceEpoch ~/ 1000,
                savedNotification.createdAt.millisecondsSinceEpoch ~/ 1000);
            expect(driftNotification.updatedAt, savedNotification.updatedAt);
            expect(driftNotification.archivedAt, savedNotification.archivedAt);

            await driftDatabase.close();
          },
        );

        test(
          'migrates targets data from native to drift database using migrateNativeToDrift',
          () async {
            final now = DateTime.now();
            final createdAt = now.subtract(const Duration(days: 1));

            final mem = MemEntity(
              Mem(
                null,
                'Test Mem for Target',
                null,
                null,
              ),
            );
            final savedMem =
                await MemRepository().receive(mem, createdAt: createdAt);

            final target = TargetEntity(
              Target(
                memId: savedMem.id,
                targetType: TargetType.equalTo,
                targetUnit: TargetUnit.count,
                value: 10,
                period: Period.aDay,
              ),
            );
            final savedTarget =
                await TargetRepository().receive(target, createdAt: createdAt);

            expect(savedTarget.id, isNotNull);
            expect(savedTarget.value.memId, savedMem.id);
            expect(savedTarget.value.targetType, TargetType.equalTo);
            expect(savedTarget.value.targetUnit, TargetUnit.count);
            expect(savedTarget.value.value, 10);
            expect(savedTarget.value.period, Period.aDay);

            if (Singleton.exists<DriftDatabaseAccessor>()) {
              final existingAccessor = DriftDatabaseAccessor();
              await existingAccessor.close();
            }
            DriftDatabaseAccessor.reset();

            final testDbFolder = await getApplicationDocumentsDirectory();
            final testDriftDbPath =
                path.join(testDbFolder.path, 'test_mem_drift.db');
            final testDriftDbFile = File(testDriftDbPath);
            if (await testDriftDbFile.exists()) {
              try {
                await testDriftDbFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final testDriftDbWalPath =
                path.join(testDbFolder.path, 'test_mem_drift.db-wal');
            final testDriftDbWalFile = File(testDriftDbWalPath);
            if (await testDriftDbWalFile.exists()) {
              try {
                await testDriftDbWalFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final testDriftDbShmPath =
                path.join(testDbFolder.path, 'test_mem_drift.db-shm');
            final testDriftDbShmFile = File(testDriftDbShmPath);
            if (await testDriftDbShmFile.exists()) {
              try {
                await testDriftDbShmFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final driftDatabase = AppDatabase();

            final driftTargetsBeforeMigration =
                await driftDatabase.select(driftDatabase.targets).get();

            if (driftTargetsBeforeMigration.isEmpty) {
              await driftDatabase.customStatement('PRAGMA foreign_keys = ON');
              await driftDatabase
                  .customStatement(defTableMems.buildCreateTableSql());
              await driftDatabase
                  .customStatement(defTableTargets.buildCreateTableSql());

              final driftTargetsBefore =
                  await driftDatabase.select(driftDatabase.targets).get();
              expect(driftTargetsBefore.length, 0);

              await migrateNativeToDrift(driftDatabase);
            }

            final driftTargets =
                await driftDatabase.select(driftDatabase.targets).get();

            expect(driftTargets.length, 1);

            final driftTarget = driftTargets.first;
            expect(driftTarget.id, savedTarget.id);
            expect(driftTarget.memId, savedTarget.value.memId);
            expect(driftTarget.type, savedTarget.value.targetType.name);
            expect(driftTarget.unit, savedTarget.value.targetUnit.name);
            expect(driftTarget.value, savedTarget.value.value);
            expect(driftTarget.period, savedTarget.value.period.name);
            expect(driftTarget.createdAt.millisecondsSinceEpoch ~/ 1000,
                savedTarget.createdAt.millisecondsSinceEpoch ~/ 1000);
            expect(driftTarget.updatedAt, savedTarget.updatedAt);
            expect(driftTarget.archivedAt, savedTarget.archivedAt);

            await driftDatabase.close();
          },
        );

        test(
          'migrates mem_relations data from native to drift database using migrateNativeToDrift',
          () async {
            final now = DateTime.now();
            final createdAt = now.subtract(const Duration(days: 1));

            final mem1 = MemEntity(
              Mem(
                null,
                'Test Mem 1 for Relation',
                null,
                null,
              ),
            );
            final savedMem1 =
                await MemRepository().receive(mem1, createdAt: createdAt);

            final mem2 = MemEntity(
              Mem(
                null,
                'Test Mem 2 for Relation',
                null,
                null,
              ),
            );
            final savedMem2 =
                await MemRepository().receive(mem2, createdAt: createdAt);

            final relation = MemRelationEntity.by(
              savedMem1.id,
              savedMem2.id,
              MemRelationType.prePost,
              0,
            );
            final savedRelation = await MemRelationRepository()
                .receive(relation, createdAt: createdAt);

            expect(savedRelation.id, isNotNull);
            expect(savedRelation.value.sourceMemId, savedMem1.id);
            expect(savedRelation.value.targetMemId, savedMem2.id);
            expect(savedRelation.value.type, MemRelationType.prePost);
            expect(savedRelation.value.value, 0);

            if (Singleton.exists<DriftDatabaseAccessor>()) {
              final existingAccessor = DriftDatabaseAccessor();
              await existingAccessor.close();
            }
            DriftDatabaseAccessor.reset();

            final testDbFolder = await getApplicationDocumentsDirectory();
            final testDriftDbPath =
                path.join(testDbFolder.path, 'test_mem_drift.db');
            final testDriftDbFile = File(testDriftDbPath);
            if (await testDriftDbFile.exists()) {
              try {
                await testDriftDbFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final testDriftDbWalPath =
                path.join(testDbFolder.path, 'test_mem_drift.db-wal');
            final testDriftDbWalFile = File(testDriftDbWalPath);
            if (await testDriftDbWalFile.exists()) {
              try {
                await testDriftDbWalFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final testDriftDbShmPath =
                path.join(testDbFolder.path, 'test_mem_drift.db-shm');
            final testDriftDbShmFile = File(testDriftDbShmPath);
            if (await testDriftDbShmFile.exists()) {
              try {
                await testDriftDbShmFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final driftDatabase = AppDatabase();

            final driftRelationsBeforeMigration =
                await driftDatabase.select(driftDatabase.memRelations).get();

            if (driftRelationsBeforeMigration.isEmpty) {
              await driftDatabase.customStatement('PRAGMA foreign_keys = ON');
              await driftDatabase
                  .customStatement(defTableMems.buildCreateTableSql());
              await driftDatabase
                  .customStatement(defTableMemRelations.buildCreateTableSql());

              final driftRelationsBefore =
                  await driftDatabase.select(driftDatabase.memRelations).get();
              expect(driftRelationsBefore.length, 0);

              await migrateNativeToDrift(driftDatabase);
            }

            final driftRelations =
                await driftDatabase.select(driftDatabase.memRelations).get();

            expect(driftRelations.length, 1);

            final driftRelation = driftRelations.first;
            expect(driftRelation.id, savedRelation.id);
            expect(driftRelation.sourceMemId, savedRelation.value.sourceMemId);
            expect(driftRelation.targetMemId, savedRelation.value.targetMemId);
            expect(driftRelation.type, savedRelation.value.type.name);
            expect(driftRelation.value, savedRelation.value.value);
            expect(driftRelation.createdAt.millisecondsSinceEpoch ~/ 1000,
                savedRelation.createdAt.millisecondsSinceEpoch ~/ 1000);
            expect(driftRelation.updatedAt, savedRelation.updatedAt);
            expect(driftRelation.archivedAt, savedRelation.archivedAt);

            await driftDatabase.close();
          },
        );

        test(
          'migrates all data from native to drift database',
          () async {
            final now = DateTime.now();
            final createdAt1 = now.subtract(const Duration(days: 1));
            final createdAt2 = now.subtract(const Duration(hours: 1));
            final updatedAt1 = now.subtract(const Duration(minutes: 30));
            final archivedAt1 = now.subtract(const Duration(minutes: 15));

            final endDate = DateAndTime.from(now.add(const Duration(days: 1)),
                timeOfDay: null);
            endDate.isAllDay = true;
            final mem1 = MemEntity(
              Mem(
                null,
                'Test Mem 1',
                null,
                DateAndTimePeriod(
                  start: DateAndTime.from(now),
                  end: endDate,
                ),
              ),
            );
            final savedMem1 =
                await MemRepository().receive(mem1, createdAt: createdAt1);

            final mem2 = MemEntity(
              Mem(
                null,
                'Test Mem 2',
                now.subtract(const Duration(days: 2)),
                null,
              ),
            );
            final savedMem2 =
                await MemRepository().receive(mem2, createdAt: createdAt2);
            await MemRepository().replace(
              SavedMemEntity(
                  savedMem2.toMap..addAll({defColUpdatedAt.name: updatedAt1})),
              updatedAt: updatedAt1,
            );
            await MemRepository().archive(
              SavedMemEntity(savedMem2.toMap
                ..addAll({defColArchivedAt.name: archivedAt1})),
              archivedAt: archivedAt1,
            );

            final memItem1 = MemItemEntity(
              MemItem(savedMem1.id, MemItemType.memo, 'Test memo'),
            );
            await MemItemRepository().receive(memItem1, createdAt: createdAt1);

            final act1 = ActEntity(
              Act.by(
                savedMem1.id,
                startWhen:
                    DateAndTime.from(now.subtract(const Duration(hours: 2))),
                endWhen:
                    DateAndTime.from(now.subtract(const Duration(hours: 1))),
              ),
            );
            await ActRepository().receive(act1, createdAt: createdAt1);

            final notification1 = MemNotificationEntity(
              MemNotification.by(
                savedMem1.id,
                MemNotificationType.repeat,
                const Duration(hours: 9).inSeconds,
                'Test notification',
              ),
            );
            await MemNotificationRepository()
                .receive(notification1, createdAt: createdAt1);

            final target1 = TargetEntity(
              Target(
                memId: savedMem1.id,
                targetType: TargetType.equalTo,
                targetUnit: TargetUnit.count,
                value: 10,
                period: Period.aDay,
              ),
            );
            await TargetRepository().receive(target1, createdAt: createdAt1);

            final relation1 = MemRelationEntity.by(
              savedMem1.id,
              savedMem2.id,
              MemRelationType.prePost,
              0,
            );
            await MemRelationRepository()
                .receive(relation1, createdAt: createdAt1);

            final nativeMems = await MemRepository().ship();
            final nativeMemItems = await MemItemRepository().ship();
            final nativeActs = await ActRepository().ship();
            final nativeNotifications =
                await MemNotificationRepository().ship();
            final nativeTargets = await TargetRepository().ship();
            final nativeRelations = await MemRelationRepository().ship();

            expect(nativeMems.length, 2);
            expect(nativeMemItems.length, 1);
            expect(nativeActs.length, 1);
            expect(nativeNotifications.length, 1);
            expect(nativeTargets.length, 1);
            expect(nativeRelations.length, 1);

            if (Singleton.exists<DriftDatabaseAccessor>()) {
              final existingAccessor = DriftDatabaseAccessor();
              await existingAccessor.close();
            }
            DriftDatabaseAccessor.reset();

            final dbFolder = await getApplicationDocumentsDirectory();
            final driftDbPath = path.join(dbFolder.path, 'test_mem_drift.db');
            final driftDbFile = File(driftDbPath);
            if (await driftDbFile.exists()) {
              try {
                await driftDbFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final driftDbWalPath =
                path.join(dbFolder.path, 'test_mem_drift.db-wal');
            final driftDbWalFile = File(driftDbWalPath);
            if (await driftDbWalFile.exists()) {
              try {
                await driftDbWalFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final driftDbShmPath =
                path.join(dbFolder.path, 'test_mem_drift.db-shm');
            final driftDbShmFile = File(driftDbShmPath);
            if (await driftDbShmFile.exists()) {
              try {
                await driftDbShmFile.delete(recursive: false);
              } catch (e) {
                // ファイルが使用中の場合は無視
              }
            }

            final driftAccessor = DriftDatabaseAccessor();
            final driftDatabase = driftAccessor.driftDatabase;

            final driftMems =
                await driftDatabase.select(driftDatabase.mems).get();
            final driftMemItems =
                await driftDatabase.select(driftDatabase.memItems).get();
            final driftActs =
                await driftDatabase.select(driftDatabase.acts).get();
            final driftNotifications = await driftDatabase
                .select(driftDatabase.memRepeatedNotifications)
                .get();
            final driftTargets =
                await driftDatabase.select(driftDatabase.targets).get();
            final driftRelations =
                await driftDatabase.select(driftDatabase.memRelations).get();

            expect(driftMems.length, nativeMems.length);
            expect(driftMemItems.length, nativeMemItems.length);
            expect(driftActs.length, nativeActs.length);
            expect(driftNotifications.length, nativeNotifications.length);
            expect(driftTargets.length, nativeTargets.length);
            expect(driftRelations.length, nativeRelations.length);

            final nativeMem1 =
                nativeMems.firstWhere((e) => e.id == savedMem1.id);
            final driftMem1 = driftMems.firstWhere((e) => e.id == savedMem1.id);

            expect(driftMem1.name, nativeMem1.value.name);
            expect(driftMem1.id, nativeMem1.id);
            expect(driftMem1.createdAt.millisecondsSinceEpoch ~/ 1000,
                nativeMem1.createdAt.millisecondsSinceEpoch ~/ 1000);
            if (driftMem1.updatedAt != null && nativeMem1.updatedAt != null) {
              expect(driftMem1.updatedAt!.millisecondsSinceEpoch ~/ 1000,
                  nativeMem1.updatedAt!.millisecondsSinceEpoch ~/ 1000);
            } else {
              expect(driftMem1.updatedAt, nativeMem1.updatedAt);
            }
            if (driftMem1.archivedAt != null && nativeMem1.archivedAt != null) {
              expect(driftMem1.archivedAt!.millisecondsSinceEpoch ~/ 1000,
                  nativeMem1.archivedAt!.millisecondsSinceEpoch ~/ 1000);
            } else {
              expect(driftMem1.archivedAt, nativeMem1.archivedAt);
            }

            final nativeMem2 =
                nativeMems.firstWhere((e) => e.id == savedMem2.id);
            final driftMem2 = driftMems.firstWhere((e) => e.id == savedMem2.id);

            expect(driftMem2.name, nativeMem2.value.name);
            expect(driftMem2.id, nativeMem2.id);
            expect(driftMem2.createdAt.millisecondsSinceEpoch ~/ 1000,
                nativeMem2.createdAt.millisecondsSinceEpoch ~/ 1000);
            if (driftMem2.updatedAt != null && nativeMem2.updatedAt != null) {
              expect(driftMem2.updatedAt!.millisecondsSinceEpoch ~/ 1000,
                  nativeMem2.updatedAt!.millisecondsSinceEpoch ~/ 1000);
            } else {
              expect(driftMem2.updatedAt, nativeMem2.updatedAt);
            }
            if (driftMem2.archivedAt != null && nativeMem2.archivedAt != null) {
              expect(driftMem2.archivedAt!.millisecondsSinceEpoch ~/ 1000,
                  nativeMem2.archivedAt!.millisecondsSinceEpoch ~/ 1000);
            } else {
              expect(driftMem2.archivedAt, nativeMem2.archivedAt);
            }

            final nativeMemItem1 = nativeMemItems.first;
            final driftMemItem1 = driftMemItems.first;

            expect(driftMemItem1.id, nativeMemItem1.id);
            expect(driftMemItem1.memId, nativeMemItem1.value.memId);
            expect(driftMemItem1.type, nativeMemItem1.value.type.name);
            expect(driftMemItem1.value, nativeMemItem1.value.value);
            expect(driftMemItem1.createdAt.millisecondsSinceEpoch ~/ 1000,
                nativeMemItem1.createdAt.millisecondsSinceEpoch ~/ 1000);

            final nativeAct1 = nativeActs.first;
            final driftAct1 = driftActs.first;

            expect(driftAct1.id, nativeAct1.id);
            expect(driftAct1.memId, nativeAct1.value.memId);
            expect(driftAct1.start, nativeAct1.value.period?.start);
            expect(driftAct1.startIsAllDay,
                nativeAct1.value.period?.start?.isAllDay);
            expect(driftAct1.end, nativeAct1.value.period?.end);
            expect(
                driftAct1.endIsAllDay, nativeAct1.value.period?.end?.isAllDay);
            expect(driftAct1.createdAt.millisecondsSinceEpoch ~/ 1000,
                nativeAct1.createdAt.millisecondsSinceEpoch ~/ 1000);

            final nativeNotification1 = nativeNotifications.first;
            final driftNotification1 = driftNotifications.first;

            expect(driftNotification1.id, nativeNotification1.id);
            expect(driftNotification1.memId, nativeNotification1.value.memId);
            expect(
                driftNotification1.type, nativeNotification1.value.type.name);
            expect(driftNotification1.timeOfDaySeconds,
                nativeNotification1.value.time);
            expect(
                driftNotification1.message, nativeNotification1.value.message);
            expect(driftNotification1.createdAt.millisecondsSinceEpoch ~/ 1000,
                nativeNotification1.createdAt.millisecondsSinceEpoch ~/ 1000);

            final nativeTarget1 = nativeTargets.first;
            final driftTarget1 = driftTargets.first;

            expect(driftTarget1.id, nativeTarget1.id);
            expect(driftTarget1.memId, nativeTarget1.value.memId);
            expect(driftTarget1.type, nativeTarget1.value.targetType.name);
            expect(driftTarget1.unit, nativeTarget1.value.targetUnit.name);
            expect(driftTarget1.value, nativeTarget1.value.value);
            expect(driftTarget1.period, nativeTarget1.value.period.name);
            expect(driftTarget1.createdAt.millisecondsSinceEpoch ~/ 1000,
                nativeTarget1.createdAt.millisecondsSinceEpoch ~/ 1000);

            final nativeRelation1 = nativeRelations.first;
            final driftRelation1 = driftRelations.first;

            expect(driftRelation1.id, nativeRelation1.id);
            expect(
                driftRelation1.sourceMemId, nativeRelation1.value.sourceMemId);
            expect(
                driftRelation1.targetMemId, nativeRelation1.value.targetMemId);
            expect(driftRelation1.type, nativeRelation1.value.type.name);
            expect(driftRelation1.value, nativeRelation1.value.value);
            expect(driftRelation1.createdAt.millisecondsSinceEpoch ~/ 1000,
                nativeRelation1.createdAt.millisecondsSinceEpoch ~/ 1000);

            await driftAccessor.close();
          },
        );
      },
    );
