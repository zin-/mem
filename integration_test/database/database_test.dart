import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mem/database/database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Open database.',
    () async {
      const dbName = 'test.db';
      const dbVersion = 1;
      const tableName = 'tests';

      const integerPkName = 'id';
      const textFieldName = 'text';
      final table = DefT(
        tableName,
        [
          DefPK(integerPkName, TypeF.integer, autoincrement: true),
          DefF(textFieldName, TypeF.text),
        ],
      );

      final database = await DatabaseFactory.open(
        dbName,
        dbVersion,
        [
          table,
        ],
      );

      expect(database.name, dbName);
      expect(database.version, dbVersion);
      expect(database.tables.length, 1);
      expect(database.tables[0].toString(), contains(tableName));
    },
  );
}
