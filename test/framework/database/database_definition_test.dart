import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/database/definition/exceptions.dart';

void main() {
  test(
    'Database name is empty.',
    () => expect(
      () => DatabaseDefinitionV2('', 0, []),
      throwsA(
        (e) {
          expect(e, isA<DatabaseDefinitionException>());
          expect(e.message, 'Database name is empty.');
          return true;
        },
      ),
    ),
  );
  test(
    'Database name contains " ".',
    () => expect(
      () => DatabaseDefinitionV2('has space', 0, []),
      throwsA(
        (e) {
          expect(e, isA<DatabaseDefinitionException>());
          expect(e.message, 'Database name contains " ".');
          return true;
        },
      ),
    ),
  );
  test(
    'Database name contains "-".',
    () => expect(
      () => DatabaseDefinitionV2('has-hyphen', 0, []),
      throwsA(
        (e) {
          expect(e, isA<DatabaseDefinitionException>());
          expect(e.message, 'Database name contains "-".');
          return true;
        },
      ),
    ),
  );

  test(
    'Version is less than 1.',
    () => expect(
      () => DatabaseDefinitionV2('test_database', 0, []),
      throwsA(
        (e) {
          expect(e, isA<DatabaseDefinitionException>());
          expect(e.message, 'Version is less than 1.');
          return true;
        },
      ),
    ),
  );
}
