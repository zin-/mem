import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/database/indexed_database.dart';
import 'package:mem/logger.dart';

void main() {
  Logger(level: Level.verbose);

  testDatabaseOnWeb();
}

// TODO IndexedDBTestに追加する
void testDatabaseOnWeb() => group(
      'Database on web test',
      () {
        if (kIsWeb) {
          final defD = DefD('test_sqlite.db', 1, []);

          test(
            'Indexed database: require at least 1 table.',
            () async {
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
        }
      },
    );
