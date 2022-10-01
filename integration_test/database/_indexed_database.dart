import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/database/indexed_database.dart';
import 'package:mem/logger.dart';

import 'definitions.dart';

void main() {
  Logger(level: Level.verbose);

  testIndexedDatabase();
}

void testIndexedDatabase() => group(
      'IndexedDatabase test',
      () {
        test(
          'Indexed database: require at least 1 table.',
          () async {
            final defD = DefD(dbName, dbVersion, []);
            expect(
              () => IndexedDatabase(defD),
              throwsA(
                (e) =>
                    e is DatabaseException &&
                    e.message == 'Requires at least 1 table.',
              ),
            );
          },
          tags: 'Medium',
        );
      },
    );
