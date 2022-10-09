import 'package:flutter_test/flutter_test.dart';
import 'package:mem/database/database.dart';
import 'package:mem/database/definitions.dart';
import 'package:mem/database/indexed_database.dart';

import '../_helpers.dart';

void main() {
  test(
    'Indexed database: require at least 1 table.',
    () async {
      final defD = DefD('test.db', 1, []);
      expect(
        () => IndexedDatabase(defD),
        throwsA(
          (e) =>
              e is DatabaseException &&
              e.message == 'Requires at least 1 table.',
        ),
      );
    },
    tags: TestSize.small,
  );
}
