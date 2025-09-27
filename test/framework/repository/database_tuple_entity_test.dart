import 'package:flutter_test/flutter_test.dart';
import 'package:mem/databases/table_definitions/base.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

import 'entity_test.dart';

const _name = 'DatabaseTupleEntity test';

class TestSampleDatabaseTupleEntity extends TestSampleEntity
    with DatabaseTupleEntity<int, TestSample> {
  TestSampleDatabaseTupleEntity(Map<String, dynamic> map)
      : super(TestSample(map['a'])) {
    withMap(map);
  }
}

void main() => group(
      _name,
      () {
        test(
          '#new',
          () {
            final map = {
              TestSampleEntity.fieldNames[0]: false,
              defPkId.name: 1,
              defColCreatedAt.name: DateTime.now(),
              defColUpdatedAt.name: DateTime.now(),
              defColArchivedAt.name: null
            };

            final testObject = TestSampleDatabaseTupleEntity(map);

            expect(testObject.value.a, map[TestSampleEntity.fieldNames[0]]);
          },
        );

        test(
          '#toMap',
          () {
            final map = {
              TestSampleEntity.fieldNames[0]: false,
              defPkId.name: 1,
              defColCreatedAt.name: DateTime.now(),
              defColUpdatedAt.name: DateTime.now(),
              defColArchivedAt.name: null
            };

            final testObject = TestSampleDatabaseTupleEntity(map);

            expect(testObject.toMap, map);
          },
        );
      },
    );
