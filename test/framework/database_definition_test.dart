import 'package:flutter_test/flutter_test.dart';
import 'package:mem/framework/database/definition/database_definition.dart';
import 'package:mem/framework/database/definition/exceptions.dart';

void main() {
  group('Throws exception', () {
    test(
      ': name is empty.',
      () {
        expect(
          () => DatabaseDefinition(
            '',
            0,
            [],
          ),
          throwsA((e) {
            expect(e, isA<DatabaseDefinitionException>());
            expect(e.message, 'Database name is required.');

            return true;
          }),
        );
      },
    );

    test(
      ': name contains space.',
      () {
        expect(
          () => DatabaseDefinition(
            'test database',
            0,
            [],
          ),
          throwsA((e) {
            expect(e, isA<DatabaseDefinitionException>());
            expect(e.message, 'Database name contains " ".');

            return true;
          }),
        );
      },
    );

    test(
      ': version is less than 1.',
      () {
        expect(
          () => DatabaseDefinition(
            'test.db',
            0,
            [],
          ),
          throwsA((e) {
            expect(e, isA<DatabaseDefinitionException>());
            expect(e.message, 'Minimum version is 1.');

            return true;
          }),
        );
      },
    );
  });
}
