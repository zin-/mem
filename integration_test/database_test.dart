import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:mem/database.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Open database', () {
    test(
      'create new.',
      () async {
        const dbName = 'test.db';
        const dbVersion = 1;
        const tableName = 'tests';

        await Database.delete(dbName);
        const integerPkName = 'id';
        const textFieldName = 'text';
        final table = DefT(
          tableName,
          [
            DefPK(integerPkName, TypeF.integer, autoincrement: true),
            DefF(textFieldName, TypeF.text),
          ],
        );
        final db = await Database.open(
          dbName,
          dbVersion,
          [
            table,
          ],
        );

        expect(db.name, dbName);
        expect(db.version, dbVersion);
        expect(db.tables.length, 1);
        expect(db.tables[0].toString(), contains(tableName));

        const text = 'test text';
        final inserted = await table.insert(db, {textFieldName: text});
        expect(inserted, 1);
        const text2 = 'test text 2';
        final inserted2 = await table.insert(db, {textFieldName: text2});
        expect(inserted2, 2);

        final selected = await table.select(db);
        expect(selected, [
          {integerPkName: inserted, textFieldName: text},
          {integerPkName: inserted2, textFieldName: text2},
        ]);

        const updatedText = 'updated text';
        final updated = await table
            .update(db, {textFieldName: updatedText}, {'id': inserted});
        expect(updated, 1);

        final selectedById = await table.selectWhere(db, {'id': inserted});
        expect(selectedById.length, 1);
        expect(selectedById[0][textFieldName], updatedText);

        final deleted = await table.delete(db, {'id': inserted});
        expect(deleted, 1);

        final selectedWithoutDeleted = await table.select(db);
        expect(selectedWithoutDeleted, [
          {integerPkName: inserted2, textFieldName: text2},
        ]);
      },
    );
  });
}
