import 'package:flutter_test/flutter_test.dart';
import 'package:mem/logger/log.dart';
import 'package:mem/logger/log_service.dart';
import 'database_accessor_tests.dart' as database_accessor_tests;
import 'database_factory_tests.dart' as database_factory_tests;
import 'database_repository_tests.dart' as database_repository_tests;
import 'database_tuple_repository_tests.dart'
    as database_tuple_repository_tests;

const _name = "Framework test";

void main() => group(
      _name,
      () {
        LogService.initialize(
          Level.verbose,
          const bool.fromEnvironment('CICD', defaultValue: false),
        );

        database_factory_tests.main();
        database_accessor_tests.main();

        database_repository_tests.main();

        database_tuple_repository_tests.main();
      },
    );
