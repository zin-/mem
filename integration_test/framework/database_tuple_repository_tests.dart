import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/database/definition/column/boolean_column_definition.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/database/definition/table_definition.dart';
import 'package:mem/framework/database/factory.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/extra_column.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';

import '../../test/framework/repository/database_tuple_entity_test.dart';
import '../../test/framework/repository/entity_test.dart';

const _name = "DatabaseTupleRepository tests";

final _defColA = BooleanColumnDefinition(TestSampleEntity.fieldNames[0]);
final _defTableTestObject =
    TableDefinition('test_object', [_defColA, ...defColsBase]);
final _defDbTest = DatabaseDefinition('test_db', 1, [_defTableTestObject]);

class _TestObjectRepository extends DatabaseTupleRepositoryV2<TestSampleEntity,
    TestSampleDatabaseTupleEntity> {
  _TestObjectRepository() : super(_defDbTest, _defTableTestObject);

  @override
  TestSampleDatabaseTupleEntity pack(Map<String, dynamic> map) =>
      TestSampleDatabaseTupleEntity(map);
}

void main() => group(
      _name,
      () {
        late String databasePath;
        setUpAll(
          () async {
            databasePath =
                await DatabaseFactory.buildDatabasePath(_defDbTest.name);

            await DatabaseFactory
                // ignore: deprecated_member_use_from_same_package
                .nativeFactory
                .deleteDatabase(databasePath);
          },
        );

        test(
          '#new',
          () async {
            _TestObjectRepository();

            expect(
                await DatabaseFactory
                    // ignore: deprecated_member_use_from_same_package
                    .nativeFactory
                    .databaseExists(databasePath),
                false);
          },
        );

        group(
          'operations',
          () {
            final repository = _TestObjectRepository();

            group(
              '#count',
              () {
                setUpAll(
                  () async {
                    final falseSample = TestSampleEntity(TestSample(false));
                    final trueSample = TestSampleEntity(TestSample(true));
                    final now = DateTime.now();

                    final dbA = await DatabaseFactory.open(_defDbTest);

                    await dbA.delete(_defTableTestObject);
                    await dbA.insert(_defTableTestObject,
                        falseSample.toMap..addAll({defColCreatedAt.name: now}));
                    await dbA.insert(_defTableTestObject,
                        falseSample.toMap..addAll({defColCreatedAt.name: now}));
                    await dbA.insert(_defTableTestObject,
                        trueSample.toMap..addAll({defColCreatedAt.name: now}));
                  },
                );

                test(
                  'All.',
                  () async {
                    final count = await repository.count();

                    expect(count, 3);
                  },
                );
                test(
                  'Condition.',
                  () async {
                    final count = await repository.count(
                        condition: Equals(_defColA, false));

                    expect(count, 2);
                  },
                );
              },
            );

            group(
              '#receive',
              () {
                setUpAll(
                  () async {
                    final dbA = await DatabaseFactory.open(_defDbTest);

                    await dbA.delete(_defTableTestObject);
                  },
                );

                test(
                  'Received.',
                  () async {
                    final now = DateTime.now();
                    final entity = TestSampleEntity(TestSample(false));

                    final received =
                        await repository.receive(entity, createdAt: now);

                    expect(
                      received.toMap,
                      equals({
                        'a': entity.value.a,
                        defPkId.name: 1,
                        defColCreatedAt.name: now,
                        defColUpdatedAt.name: null,
                        defColArchivedAt.name: null,
                      }),
                    );
                  },
                );
              },
            );

            group(
              '#ship',
              () {
                final falseSample = TestSampleEntity(TestSample(false));
                final trueSample = TestSampleEntity(TestSample(true));
                final now = DateTime.now();
                final later = now.add(const Duration(seconds: 1));

                late int sampleId1;
                late int sampleId2;
                late int sampleId3;
                setUpAll(
                  () async {
                    final dbA = await DatabaseFactory.open(_defDbTest);

                    await dbA.delete(_defTableTestObject);
                    sampleId1 = await dbA.insert(_defTableTestObject,
                        falseSample.toMap..addAll({defColCreatedAt.name: now}));
                    sampleId2 = await dbA.insert(_defTableTestObject,
                        trueSample.toMap..addAll({defColCreatedAt.name: now}));
                    sampleId3 = await dbA.insert(
                        _defTableTestObject,
                        falseSample.toMap
                          ..addAll({defColCreatedAt.name: later}));
                  },
                );

                test(
                  'All.',
                  () async {
                    final shipped = await repository.ship();

                    expect(shipped, hasLength(3));
                    expect(shipped[0].id, equals(sampleId1));
                    expect(shipped[0].createdAt, equals(now));
                  },
                );
                test(
                  'Condition.',
                  () async {
                    final shipped = await repository.ship(
                      condition: Equals(_defColA, false),
                    );

                    expect(shipped, hasLength(2));
                  },
                );
                test(
                  'GroupBy.',
                  () async {
                    final shipped = await repository.ship(
                        groupBy: GroupBy([_defColA],
                            extraColumns: [Max(defColCreatedAt)]));

                    expect(shipped, hasLength(2));
                    expect(shipped[0].id, equals(sampleId3));
                    expect(shipped[0].createdAt, equals(later));
                  },
                );
                test(
                  'OrderBy.',
                  () async {
                    final shipped =
                        await repository.ship(orderBy: [Descending(defPkId)]);

                    expect(shipped, hasLength(3));
                    expect(shipped[0].id, sampleId3);
                  },
                );
                test(
                  'Offset.',
                  () async {
                    final shipped = await repository.ship(offset: 1);

                    expect(shipped, hasLength(2));
                    expect(shipped[0].id, sampleId2);
                  },
                );
                test(
                  'Limit.',
                  () async {
                    final shipped = await repository.ship(limit: 2);

                    expect(shipped, hasLength(2));
                    expect(shipped[1].id, sampleId2);
                  },
                );
              },
            );

            group(
              '#replace',
              () {
                late TestSampleDatabaseTupleEntity savedFalseSample;
                setUpAll(
                  () async {
                    final falseSample = TestSampleEntity(TestSample(false));
                    final now = DateTime.now();

                    final dbA = await DatabaseFactory.open(_defDbTest);

                    await dbA.delete(_defTableTestObject);
                    savedFalseSample =
                        TestSampleDatabaseTupleEntity(falseSample.toMap
                          ..addAll({
                            defPkId.name: await dbA.insert(
                                _defTableTestObject,
                                falseSample.toMap
                                  ..addAll({defColCreatedAt.name: now})),
                            defColCreatedAt.name: now
                          }));
                  },
                );

                test('Updated.', () async {
                  final updatedAt = DateTime.now();
                  final updating = TestSampleDatabaseTupleEntity(
                      savedFalseSample.toMap
                        ..update(
                            TestSampleEntity.fieldNames[0], (value) => false));

                  final updated =
                      await repository.replace(updating, updatedAt: updatedAt);

                  expect(updated.value.a, equals(updating.value.a));
                  expect(updated.updatedAt, equals(updatedAt));
                });
              },
            );

            group(
              '#archive',
              () {
                late TestSampleDatabaseTupleEntity savedFalseSample;
                setUpAll(
                  () async {
                    final falseSample = TestSampleEntity(TestSample(false));
                    final now = DateTime.now();

                    final dbA = await DatabaseFactory.open(_defDbTest);

                    await dbA.delete(_defTableTestObject);
                    savedFalseSample =
                        TestSampleDatabaseTupleEntity(falseSample.toMap
                          ..addAll({
                            defPkId.name: await dbA.insert(
                                _defTableTestObject,
                                falseSample.toMap
                                  ..addAll({defColCreatedAt.name: now})),
                            defColCreatedAt.name: now
                          }));
                  },
                );

                test(
                  'Archived.',
                  () async {
                    final archivedAt = DateTime.now();

                    final archived = await repository.archive(savedFalseSample,
                        archivedAt: archivedAt);

                    expect(archived.archivedAt, equals(archivedAt));
                  },
                );
              },
            );

            group(
              '#unarchive',
              () {
                late TestSampleDatabaseTupleEntity savedArchivedSample;
                setUpAll(
                  () async {
                    final falseSample = TestSampleEntity(TestSample(false));
                    final now = DateTime.now();

                    final dbA = await DatabaseFactory.open(_defDbTest);

                    await dbA.delete(_defTableTestObject);
                    savedArchivedSample =
                        TestSampleDatabaseTupleEntity(falseSample.toMap
                          ..addAll({
                            defPkId.name: await dbA.insert(
                                _defTableTestObject,
                                falseSample.toMap
                                  ..addAll({
                                    defColCreatedAt.name: now,
                                    defColArchivedAt.name: now
                                  })),
                            defColCreatedAt.name: now,
                            defColArchivedAt.name: now
                          }));
                  },
                );

                test(
                  'Unarchived.',
                  () async {
                    final updatedAt = DateTime.now();

                    final archived = await repository
                        .unarchive(savedArchivedSample, updatedAt: updatedAt);

                    expect(archived.updatedAt, equals(updatedAt));
                    expect(archived.archivedAt, isNull);
                  },
                );
              },
            );

            group(
              '#waste',
              () {
                late TestSampleDatabaseTupleEntity savedFalseSample;
                setUpAll(
                  () async {
                    final falseSample = TestSampleEntity(TestSample(false));
                    final now = DateTime.now();

                    final dbA = await DatabaseFactory.open(_defDbTest);

                    await dbA.delete(_defTableTestObject);
                    savedFalseSample =
                        TestSampleDatabaseTupleEntity(falseSample.toMap
                          ..addAll({
                            defPkId.name: await dbA.insert(
                                _defTableTestObject,
                                falseSample.toMap
                                  ..addAll({defColCreatedAt.name: now})),
                            defColCreatedAt.name: now
                          }));
                  },
                );

                test(
                  'Wasted.',
                  () async {
                    final wastedList = await repository.waste(
                        condition: Equals(defPkId, savedFalseSample.id));

                    expect(wastedList, hasLength(equals(1)));
                    expect(wastedList[0].toMap, equals(savedFalseSample.toMap));
                  },
                );
              },
            );
          },
        );
      },
    );
