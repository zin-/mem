import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

import 'entity_test.dart';

const _name = 'DatabaseTupleEntity test';

class TestObjectDatabaseTupleEntity extends TestObjectEntity
    with DatabaseTupleEntity<int> {
  TestObjectDatabaseTupleEntity(super.a);

  TestObjectDatabaseTupleEntity.fromMap(Map<String, dynamic> map)
      : super.fromMap(map) {
    withMap(map);
  }

  @override
  TestObjectDatabaseTupleEntity copiedWith({bool Function()? a}) =>
      TestObjectDatabaseTupleEntity.fromMap(
          toMap..addAll(super.copiedWith(a: a).toMap));
}

void main() => group(
      _name,
      () {
        test(
          '#new',
          () {
            const a = false;

            final testObject = TestObjectDatabaseTupleEntity(a);

            expect(testObject.a, equals(a));
          },
        );

        test(
          '#fromMap',
          () {
            final map = {
              TestObjectEntity.fieldNames[0]: false,
              defPkId.name: 1,
              defColCreatedAt.name: DateTime.now(),
              defColUpdatedAt.name: DateTime.now(),
              defColArchivedAt.name: null
            };

            final testObject = TestObjectDatabaseTupleEntity.fromMap(map);

            expect(testObject.a, map[TestObjectEntity.fieldNames[0]]);
          },
        );

        test(
          '#toMap',
          () {
            final map = {
              TestObjectEntity.fieldNames[0]: false,
              defPkId.name: 1,
              defColCreatedAt.name: DateTime.now(),
              defColUpdatedAt.name: DateTime.now(),
              defColArchivedAt.name: null
            };

            final testObject = TestObjectDatabaseTupleEntity.fromMap(map);

            expect(testObject.toMap, map);
          },
        );

        test(
          '#copiedWith',
          () {
            final from = TestObjectDatabaseTupleEntity.fromMap({
              TestObjectEntity.fieldNames[0]: false,
              defPkId.name: 1,
              defColCreatedAt.name: DateTime.now(),
              defColUpdatedAt.name: DateTime.now(),
              defColArchivedAt.name: DateTime.now()
            });

            final copied = from.copiedWith(a: () => true);

            expect(copied.a, equals(true));
            expect(copied.id, equals(from.id));
            expect(copied.createdAt, equals(from.createdAt));
            expect(copied.updatedAt, equals(from.updatedAt));
            expect(copied.archivedAt, equals(from.archivedAt));
          },
        );
      },
    );
