import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/factory.dart';
import 'package:mem/framework/repository/condition/conditions.dart';
import 'package:mem/framework/repository/database_repository.dart';
import 'package:mem/framework/repository/database_tuple_entity.dart';
import 'package:mem/framework/repository/database_tuple_repository_v1.dart';
import 'package:mem/framework/repository/entity.dart';
import 'package:mem/framework/repository/extra_column.dart';
import 'package:mem/framework/repository/group_by.dart';
import 'package:mem/framework/repository/order_by.dart';

import 'database_definitions.dart';

const _name = "DatabaseTupleRepository tests";

class TestEntity extends EntityV1 {}

class SavedTestEntity extends TestEntity with SavedDatabaseTupleMixinV1<int> {}

class TestRepository
    extends DatabaseTupleRepositoryV1<TestEntity, SavedTestEntity, int> {
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
          for (final testDefDatabase in [
            sampleDefDb,
            sampleDefDBAddedTable,
            sampleDefDBAddedColumn,
          ]) {
            await DatabaseFactory
                // ignore: deprecated_member_use_from_same_package
                .nativeFactory
                .deleteDatabase(
              await DatabaseFactory.buildDatabasePath(testDefDatabase.name),
            );
          }

          DatabaseTupleRepositoryV1.databaseAccessor =
              await DatabaseRepository().receive(sampleDefDBAddedColumn);
        });
        tearDownAll(() {
          DatabaseFactory.onTest = false;
          DatabaseTupleRepositoryV1.databaseAccessor = null;
        });

        test(
          ": count.",
          () async {
            final repository = TestRepository(sampleDefTable);

            final count = await repository.count(
              condition: EqualsV1(sampleDefPk.name, 1),
            );

            expect(count, equals(0));
          },
        );

        group(
          'ship',
          () {
            test(
              'group by',
              () async {
                final repository = TestRepository(sampleDefTable);

                final shipped = await repository.ship(
                  groupBy: GroupBy(
                    [sampleDefColBoolean],
                    extraColumns: [Max(sampleDefPk)],
                  ),
                );

                expect(shipped, hasLength(0));
              },
            );

            test(
              'order by',
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
      },
    );
