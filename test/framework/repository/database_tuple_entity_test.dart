import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';

import 'entity_test.dart';

const _name = 'DatabaseTupleEntity test';

class TestSampleDatabaseTupleEntity extends TestSampleEntity
    with DatabaseTupleEntityV1<int, TestSample> {
  TestSampleDatabaseTupleEntity(Map<String, dynamic> map)
      : super(TestSample(map['a'])) {
    withBaseColumns(map);
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
              'id': 1,
              'createdAt': DateTime.now(),
              'updatedAt': DateTime.now(),
              'archivedAt': null
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
              'id': 1,
              'createdAt': DateTime.now(),
              'updatedAt': DateTime.now(),
              'archivedAt': null
            };

            final testObject = TestSampleDatabaseTupleEntity(map);

            expect(testObject.toMap, map);
          },
        );
      },
    );
