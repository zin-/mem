import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/database_factory.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/logger.dart';
import 'package:mem/repositories/repository.dart';

class TestRepository implements DatabaseTableRepository {
  @override
  Table table;

  TestRepository(this.table);
}

final testTable = DefT('tests', [
  DefPK('id', TypeC.text),
]);
final testDatabase = DefD('test.db', 1, [testTable]);

void main() async {
  Logger(level: Level.verbose);
  DatabaseManager(onTest: true);

  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test('description', () async {
    final database = await DatabaseManager().open(testDatabase);
    final testRepository = TestRepository(database.getTable(testTable.name));

    expect(testRepository.table.definition, testTable);
  });
}
