import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/factory.dart';
import 'package:mem/framework/repository/database_repository.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/database_tuple_repository.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/order_by.dart';

import 'database_definitions.dart';

const _name = "DatabaseTupleRepository tests";

class TestEntity extends EntityV1 {}

class SavedTestEntity extends TestEntity with SavedDatabaseTupleMixin<int> {}

class TestRepository
    extends DatabaseTupleRepository<TestEntity, SavedTestEntity, int> {
  TestRepository(super.tableDefinition);

  @override
  SavedTestEntity pack(Map<String, dynamic> tuple) {
    // TODO: implement pack
    throw UnimplementedError();
  }

  @override
  Map<String, dynamic> unpack(TestEntity entity) {
    // TODO: implement unpack
    throw UnimplementedError();
  }
}

void main() => group(
      _name,
      () {
        setUpAll(() async {
          DatabaseFactory.onTest = true;

          DatabaseTupleRepository.databaseAccessor =
              await DatabaseRepository().receive(sampleDefDBAddedColumn);
        });
        tearDownAll(() {
          DatabaseFactory.onTest = false;
          DatabaseTupleRepository.databaseAccessor = null;
        });

        test(
          ": ship",
          () async {
            final repository = TestRepository(sampleDefTable);

            final shipped = await repository.ship(
              orderBy: [
                Ascending(sampleDefPk),
                Descending(sampleDefColInteger),
              ],
              offset: 1,
              limit: 1,
            );

            expect(shipped, hasLength(0));
          },
        );
      },
    );
