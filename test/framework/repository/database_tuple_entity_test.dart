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
      },
    );
