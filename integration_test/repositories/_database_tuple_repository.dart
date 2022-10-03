import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/_database_tuple_repository.dart';

void main() async {
  Logger(level: Level.verbose);
  DatabaseManager(onTest: true);

  testDatabaseTupleRepository();
}

class TestEntity extends DatabaseTupleEntity {
  TestEntity({
    int? id,
    DateTime? archivedAt,
  }) : super(id: id, archivedAt: archivedAt);

  @override
  TestEntity.fromMap(Map<String, dynamic> valueMap) : super.fromMap(valueMap);
}

class TestRepository extends DatabaseTupleRepository<TestEntity> {
  TestRepository(Table table) : super(table);

  @override
  TestEntity fromMap(Map<String, dynamic> valueMap) =>
      TestEntity.fromMap(valueMap);
}

void testDatabaseTupleRepository() => group(
      'DatabaseTupleRepository test',
      () {
        if (Platform.isAndroid || Platform.isWindows) {
          final testTable = DefT('tests', [
            DefPK('id', TypeC.integer, autoincrement: true),
            ...defaultColumnDefinitions,
          ]);
          final testDatabase = DefD('test.db', 1, [testTable]);

          late TestRepository testRepository;

          setUp(() async {
            testRepository = TestRepository(
              (await DatabaseManager().open(testDatabase))
                  .getTable(testTable.name),
            );
          });
          tearDown(() async {
            await DatabaseManager().delete(testDatabase.name);
          });

          test(
            'new',
            () async {
              final database = await DatabaseManager().open(testDatabase);
              TestRepository(database.getTable(testTable.name));
            },
            tags: 'Medium',
          );

          test(
            'receive',
            () async {
              final result = await testRepository.receive(
                TestEntity(),
              );

              expect(result.id, isNotNull);
              expect(result.createdAt, const TypeMatcher<DateTime>());
              expect(result.updatedAt, isNull);
              expect(result.archivedAt, isNull);

              expect(result.isSaved(), true);
            },
            tags: 'Medium',
          );

          group(
            'ship',
            () {
              test(
                'all',
                () async {
                  final received1 = await testRepository.receive(
                    TestEntity(archivedAt: null),
                  );
                  final received2 = await testRepository.receive(
                    TestEntity(archivedAt: DateTime.now()),
                  );

                  final shipped = await testRepository.ship();

                  expect(shipped.length, 2);
                  expect(shipped[0].toMap(), received1.toMap());
                  expect(shipped[1].toMap(), received2.toMap());

                  final shipped2 = await testRepository.ship(
                    whereMap: buildNullableWhere(
                      archivedAtColumnName,
                      null,
                    ),
                  );

                  expect(
                    shipped2.map((e) => e.toMap()).toString(),
                    shipped.map((e) => e.toMap()).toString(),
                  );
                },
                tags: 'Medium',
              );

              test(
                'archived',
                () async {
                  await testRepository.receive(
                    TestEntity(archivedAt: null),
                  );
                  final received2 = await testRepository.receive(
                    TestEntity(archivedAt: DateTime.now()),
                  );

                  final shipped = await testRepository.ship(
                    whereMap: buildNullableWhere(
                      archivedAtColumnName,
                      true,
                    ),
                  );

                  expect(shipped.length, 1);
                  expect(shipped[0].toMap(), received2.toMap());
                },
                tags: 'Medium',
              );

              test(
                'unarchived',
                () async {
                  final received1 = await testRepository.receive(
                    TestEntity(archivedAt: null),
                  );
                  await testRepository.receive(
                    TestEntity(archivedAt: DateTime.now()),
                  );

                  final shipped = await testRepository.ship(
                    whereMap: buildNullableWhere(
                      archivedAtColumnName,
                      false,
                    ),
                  );

                  expect(shipped.length, 1);
                  expect(shipped[0].toMap(), received1.toMap());
                },
                tags: 'Medium',
              );
            },
          );

          test(
            'shipById',
            () async {
              final received = await testRepository.receive(
                TestEntity(),
              );

              final shipped = await testRepository.shipById(received.id);

              expect(shipped.toMap(), received.toMap());
            },
            tags: 'Medium',
          );

          test(
            'update',
            () async {
              final received = await testRepository.receive(
                TestEntity(),
              );

              final updated = await testRepository.update(received);

              expect(updated.updatedAt, isNotNull);
            },
            tags: 'Medium',
          );

          test(
            'archive',
            () async {
              final received = await testRepository.receive(
                TestEntity(),
              );

              final archived = await testRepository.archive(received);

              expect(archived.isArchived(), true);
            },
            tags: 'Medium',
          );

          test(
            'unarchive',
            () async {
              final received = await testRepository.receive(
                TestEntity(archivedAt: DateTime.now()),
              );

              final unarchived = await testRepository.unarchive(received);

              expect(unarchived.isArchived(), false);
            },
            tags: 'Medium',
          );

          group(
            'discardById',
            () {
              test(
                ': success',
                () async {
                  final received = await testRepository.receive(
                    TestEntity(),
                  );

                  final discardResult =
                      await testRepository.discardById(received.id);

                  expect(discardResult, true);
                },
                tags: 'Medium',
              );

              test(
                ': fail',
                () async {
                  final discardResult = await testRepository.discardById(0);

                  expect(discardResult, false);
                },
                tags: 'Medium',
              );
            },
          );

          test(
            'discardAll',
            () async {
              await testRepository.receive(
                TestEntity(),
              );
              await testRepository.receive(
                TestEntity(),
              );

              final discardedCount = await testRepository.discardAll();

              expect(discardedCount, 2);
            },
            tags: 'Medium',
          );
        }
      },
    );
