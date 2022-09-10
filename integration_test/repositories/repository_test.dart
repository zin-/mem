import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/repository.dart';

class TestEntity extends DatabaseTableEntity {
  @override
  TestEntity.fromMap(Map<String, dynamic> valueMap) : super.fromMap(valueMap);
}

class TestRepository extends DatabaseTableRepository<TestEntity> {
  TestRepository(Table table) : super(table);

  @override
  TestEntity fromMap(Map<String, dynamic> valueMap) =>
      TestEntity.fromMap(valueMap);
}

final testTable = DefT('tests', [
  DefPK('id', TypeC.integer, autoincrement: true),
  ...defaultColumnDefinitions,
]);
final testDatabase = DefD('test.db', 1, [testTable]);

void main() async {
  Logger(level: Level.verbose);
  DatabaseManager(onTest: true);

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestRepository testRepository;

  setUp(() async {
    testRepository = TestRepository(
      (await DatabaseManager().open(testDatabase)).getTable(testTable.name),
    );
  });
  tearDown(() async {
    await DatabaseManager().delete(testDatabase.name);
  });

  test(
    'new',
    () async {
      final database = await DatabaseManager().open(testDatabase);
      final testRepository = TestRepository(database.getTable(testTable.name));

      expect(testRepository.table.definition, testTable);
    },
  );

  test(
    'receive',
    () async {
      final result = await testRepository.receive({});

      expect(result.id, isNotNull);
      expect(result.createdAt, const TypeMatcher<DateTime>());
      expect(result.updatedAt, isNull);
      expect(result.archivedAt, isNull);
    },
  );

  group('ship', () {
    test(
      ': all',
      () async {
        final received1 = await testRepository.receive({
          archivedAtColumnName: null,
        });
        final received2 = await testRepository.receive({
          archivedAtColumnName: DateTime.now(),
        });

        final shipped = await testRepository.ship();

        expect(shipped.length, 2);
        expect(shipped[0].toMap(), received1.toMap());
        expect(shipped[1].toMap(), received2.toMap());
      },
    );

    test(
      ': archived',
      () async {
        await testRepository.receive({
          archivedAtColumnName: null,
        });
        final received2 = await testRepository.receive({
          archivedAtColumnName: DateTime.now(),
        });

        final shipped = await testRepository.ship(archived: true);

        expect(shipped.length, 1);
        expect(shipped[0].toMap(), received2.toMap());
      },
    );

    test(
      ': not archived',
      () async {
        final received1 = await testRepository.receive({
          archivedAtColumnName: null,
        });
        await testRepository.receive({
          archivedAtColumnName: DateTime.now(),
        });

        final shipped = await testRepository.ship(archived: false);

        expect(shipped.length, 1);
        expect(shipped[0].toMap(), received1.toMap());
      },
    );
  });

  test(
    'shipById',
    () async {
      final received = await testRepository.receive({});

      final shipped = await testRepository.shipById(received.id);

      expect(shipped.toMap(), received.toMap());
    },
  );

  test(
    'update',
    () async {
      final received = await testRepository.receive({});

      final updated = await testRepository.update(received);

      expect(updated.updatedAt, isNotNull);
    },
  );

  test(
    'archive',
    () async {
      final received = await testRepository.receive({});

      final updated = await testRepository.archive(received);

      expect(updated.archivedAt, isNotNull);
    },
  );

  test(
    'unarchive',
    () async {
      final received = await testRepository.receive({
        archivedAtColumnName: DateTime.now(),
      });

      final updated = await testRepository.unarchive(received);

      expect(updated.archivedAt, isNull);
    },
  );

  group('discardById', () {
    test(
      ': success',
      () async {
        final received = await testRepository.receive({
          archivedAtColumnName: DateTime.now(),
        });

        final discardResult = await testRepository.discardById(received.id);

        expect(discardResult, true);
      },
    );

    test(
      ': fail',
      () async {
        final discardResult = await testRepository.discardById(0);

        expect(discardResult, false);
      },
    );
  });
}
