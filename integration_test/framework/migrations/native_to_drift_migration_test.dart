import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/database.dart' hide Mem, MemItem, Act, Target;
import 'package:mem/databases/table_definitions/base.dart';
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
import 'package:mem/framework/database/factory.dart';
import 'package:mem/framework/date_and_time/date_and_time.dart';
import 'package:mem/framework/date_and_time/date_and_time_period.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

const _name = "Migrations tests Native to Drift";

void main() => group(
      _name,
      () {
        setUpAll(() {
          DatabaseFactory.onTest = true;
          setOnTest(true);
        });

        setUp(() async {
          await DatabaseTupleRepository.close();

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
            await driftDbFile.delete();
          }

          final driftDbWalPath =
              path.join(dbFolder.path, 'test_mem_drift.db-wal');
          final driftDbWalFile = File(driftDbWalPath);
          if (await driftDbWalFile.exists()) {
            await driftDbWalFile.delete();
          }

          final driftDbShmPath =
              path.join(dbFolder.path, 'test_mem_drift.db-shm');
          final driftDbShmFile = File(driftDbShmPath);
          if (await driftDbShmFile.exists()) {
            await driftDbShmFile.delete();
          }
        });

        tearDownAll(() {
          DatabaseFactory.onTest = false;
          setOnTest(false);
        });

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

            final driftDatabase = AppDatabase();

            await driftDatabase.close();

            final dbFolder = await getApplicationDocumentsDirectory();
            final driftDbPath = path.join(dbFolder.path, 'test_mem_drift.db');
            final driftDbFile = File(driftDbPath);
            if (await driftDbFile.exists()) {
              await driftDbFile.delete();
            }

            final driftDbWalPath =
                path.join(dbFolder.path, 'test_mem_drift.db-wal');
            final driftDbWalFile = File(driftDbWalPath);
            if (await driftDbWalFile.exists()) {
              await driftDbWalFile.delete();
            }

            final driftDbShmPath =
                path.join(dbFolder.path, 'test_mem_drift.db-shm');
            final driftDbShmFile = File(driftDbShmPath);
            if (await driftDbShmFile.exists()) {
              await driftDbShmFile.delete();
            }

            final newDriftDatabase = AppDatabase();

            final driftMems =
                await newDriftDatabase.select(newDriftDatabase.mems).get();
            final driftMemItems =
                await newDriftDatabase.select(newDriftDatabase.memItems).get();
            final driftActs =
                await newDriftDatabase.select(newDriftDatabase.acts).get();
            final driftNotifications = await newDriftDatabase
                .select(newDriftDatabase.memRepeatedNotifications)
                .get();
            final driftTargets =
                await newDriftDatabase.select(newDriftDatabase.targets).get();
            final driftRelations = await newDriftDatabase
                .select(newDriftDatabase.memRelations)
                .get();

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

            await newDriftDatabase.close();
          },
        );
      },
    );
