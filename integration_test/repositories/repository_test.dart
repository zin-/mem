import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/repository.dart';

class TestEntity implements DatabaseTableEntity {
  @override
  final int id;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  final DateTime? archivedAt;

  TestEntity({
    required this.id,
    required this.createdAt,
    this.updatedAt,
    this.archivedAt,
  });

  factory TestEntity.fromMap(Map<String, dynamic> valueMap) => v(
        {'valueMap': valueMap},
        () => TestEntity(
          id: valueMap[idColumnName],
          createdAt: valueMap[createdAtColumnName],
          updatedAt: valueMap[updatedAtColumnName],
          archivedAt: valueMap[archivedAtColumnName],
        ),
      );
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

  late final TestRepository testRepository;

  setUpAll(() async {
    testRepository = TestRepository(
      (await DatabaseManager().open(testDatabase)).getTable(testTable.name),
    );
  });
  tearDownAll(() async {
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

      // FIXME データベースに直接アクセスして保存されているか確認する
    },
  );
}
