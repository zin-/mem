import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/database/definition/exceptions.dart';

void main() {
  test(
    'Database name is empty.',
    () => expect(
      () => DatabaseDefinition('', 0, []),
      throwsA(
        (e) {
          expect(e, isA<DatabaseDefinitionException>());
          expect(e.toString(),
              'Instance of \'DatabaseDefinitionException\': {message: Database name is empty.}');
          return true;
        },
      ),
    ),
  );
  test(
    'Database name contains " ".',
    () => expect(
      () => DatabaseDefinition('has space', 0, []),
      throwsA(
        (e) {
          expect(e, isA<DatabaseDefinitionException>());
          expect(e.toString(),
              'Instance of \'DatabaseDefinitionException\': {message: Database name contains " ".}');
          return true;
        },
      ),
    ),
  );
  test(
    'Database name contains "-".',
    () => expect(
      () => DatabaseDefinition('has-hyphen', 0, []),
      throwsA(
        (e) {
          expect(e, isA<DatabaseDefinitionException>());
          expect(e.toString(),
              'Instance of \'DatabaseDefinitionException\': {message: Database name contains "-".}');
          return true;
        },
      ),
    ),
  );

  test(
    'Version is less than 1.',
    () => expect(
      () => DatabaseDefinition('test_database', 0, []),
      throwsA(
        (e) {
          expect(e, isA<DatabaseDefinitionException>());
          expect(e.toString(),
              'Instance of \'DatabaseDefinitionException\': {message: Version is less than 1.}');
          return true;
        },
      ),
    ),
  );
}
