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

final _defColA = BooleanColumnDefinition(TestObjectEntity.fieldNames[0]);
final _defTableTestObject =
    TableDefinition('test_object', [_defColA, ...defColsBase]);
final _defDbTest = DatabaseDefinition('test_db', 1, [_defTableTestObject]);

class _TestObjectRepository extends DatabaseTupleRepository<TestObjectEntity,
    TestObjectDatabaseTupleEntity> {
  _TestObjectRepository() : super(_defDbTest, _defTableTestObject);

  @override
  TestObjectDatabaseTupleEntity pack(Map<String, dynamic> map) =>
      TestObjectDatabaseTupleEntity.fromMap(map);
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
                    final falseSample = TestObjectEntity(false);
                    final trueSample = TestObjectEntity(true);
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
                  ': all.',
                  () async {
                    final count = await repository.count();

                    expect(count, 3);
                  },
                );
                test(
                  ': condition.',
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
                  ': received.',
                  () async {
                    final now = DateTime.now();
                    final entity = TestObjectEntity(false);

                    final received =
                        await repository.receive(entity, createdAt: now);

                    expect(
                        received,
                        equals(TestObjectDatabaseTupleEntity(entity.a).withMap(
                            {defPkId.name: 1, defColCreatedAt.name: now})));
                  },
                );
              },
            );

            group(
              '#ship',
              () {
                final falseSample = TestObjectEntity(false);
                final trueSample = TestObjectEntity(true);
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
                  ': all.',
                  () async {
                    final shipped = await repository.ship();

                    expect(shipped, hasLength(3));
                    expect(shipped[0].id, equals(sampleId1));
                    expect(shipped[0].createdAt, equals(now));
                  },
                );
                test(
                  ': condition.',
                  () async {
                    final shipped = await repository.ship(
                      condition: Equals(_defColA, false),
                    );

                    expect(shipped, hasLength(2));
                  },
                );
                test(
                  ': groupBy.',
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
                  ': orderBy.',
                  () async {
                    final shipped =
                        await repository.ship(orderBy: [Descending(defPkId)]);

                    expect(shipped, hasLength(3));
                    expect(shipped[0].id, sampleId3);
                  },
                );
                test(
                  ': offset.',
                  () async {
                    final shipped = await repository.ship(offset: 1);

                    expect(shipped, hasLength(2));
                    expect(shipped[0].id, sampleId2);
                  },
                );
                test(
                  ': limit.',
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
                late TestObjectDatabaseTupleEntity savedFalseSample;
                setUpAll(
                  () async {
                    final falseSample = TestObjectEntity(false);
                    final now = DateTime.now();

                    final dbA = await DatabaseFactory.open(_defDbTest);

                    await dbA.delete(_defTableTestObject);
                    savedFalseSample =
                        TestObjectDatabaseTupleEntity.fromMap(falseSample.toMap
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
                  ': updated.',
                  () async {
                    final updatedAt = DateTime.now();
                    final updating = savedFalseSample.copiedWith(
                      a: () => true,
                    );

                    final updated = await repository.replace(updating,
                        updatedAt: updatedAt);

                    expect(updated.a, equals(updating.a));
                    expect(updated.updatedAt, equals(updatedAt));
                  },
                );
              },
            );

            group(
              '#archive',
              () {
                late TestObjectDatabaseTupleEntity savedFalseSample;
                setUpAll(
                  () async {
                    final falseSample = TestObjectEntity(false);
                    final now = DateTime.now();

                    final dbA = await DatabaseFactory.open(_defDbTest);

                    await dbA.delete(_defTableTestObject);
                    savedFalseSample =
                        TestObjectDatabaseTupleEntity.fromMap(falseSample.toMap
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
                  ': archived.',
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
                late TestObjectDatabaseTupleEntity savedArchivedSample;
                setUpAll(
                  () async {
                    final falseSample = TestObjectEntity(false);
                    final now = DateTime.now();

                    final dbA = await DatabaseFactory.open(_defDbTest);

                    await dbA.delete(_defTableTestObject);
                    savedArchivedSample =
                        TestObjectDatabaseTupleEntity.fromMap(falseSample.toMap
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
                  ': unarchived.',
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
                late TestObjectDatabaseTupleEntity savedFalseSample;
                setUpAll(
                  () async {
                    final falseSample = TestObjectEntity(false);
                    final now = DateTime.now();

                    final dbA = await DatabaseFactory.open(_defDbTest);

                    await dbA.delete(_defTableTestObject);
                    savedFalseSample =
                        TestObjectDatabaseTupleEntity.fromMap(falseSample.toMap
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
                  ': wasted.',
                  () async {
                    final wastedList = await repository.waste(
                        condition: Equals(defPkId, savedFalseSample.id));

                    expect(wastedList, hasLength(equals(1)));
                    expect(wastedList[0], equals(savedFalseSample));
                  },
                );
              },
            );
          },
        );
      },
    );
