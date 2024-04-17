import 'package:flutter_test/flutter_test.dart';
import 'database_accessor_tests.dart' as database_accessor_tests;
import 'database_factory_tests.dart' as database_factory_tests;
import 'database_tuple_repository_tests.dart'
    as database_tuple_repository_tests;

const _name = "Framework test";

void main() => group(
      _name,
      () {
        database_factory_tests.main();
        database_accessor_tests.main();

        database_tuple_repository_tests.main();
      },
    );
