import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_manager.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/repositories/_database_tuple_repository.dart';

import '../_helpers.dart';

void main() async {
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
              (await DatabaseManager(onTest: true).open(testDatabase))
                  .getTable(testTable.name),
            );
          });
          tearDown(() async {
            await DatabaseManager(onTest: true).delete(testDatabase.name);
          });

          test(
            'new',
            () async {
              final database = await DatabaseManager(onTest: true).open(testDatabase);
              TestRepository(database.getTable(testTable.name));
            },
            tags: TestSize.medium,
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
            tags: TestSize.medium,
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
                tags: TestSize.medium,
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
                tags: TestSize.medium,
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
                tags: TestSize.medium,
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
            tags: TestSize.medium,
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
            tags: TestSize.medium,
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
            tags: TestSize.medium,
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
            tags: TestSize.medium,
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
                tags: TestSize.medium,
              );

              test(
                ': fail',
                () async {
                  final discardResult = await testRepository.discardById(0);

                  expect(discardResult, false);
                },
                tags: TestSize.medium,
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
            tags: TestSize.medium,
          );
        }
      },
    );
