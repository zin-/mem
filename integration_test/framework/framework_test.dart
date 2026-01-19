import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/logger/log.dart';
import 'package:mem/features/logger/log_service.dart';
import 'migrations/native_to_drift_migration_test.dart'
    as native_to_drift_migration_test;
import 'database_accessor_tests.dart' as database_accessor_tests;
import 'database_factory_tests.dart' as database_factory_tests;
import 'database_repository_tests.dart' as database_repository_tests;
import 'database_tuple_repository_tests.dart'
    as database_tuple_repository_tests;

const _name = "Framework test";

void main() => group(
      _name,
      () {
        LogService(
          level: Level.verbose,
          enableSimpleLog:
              const bool.fromEnvironment('CICD', defaultValue: false),
        );

        database_factory_tests.main();
        database_accessor_tests.main();

        database_repository_tests.main();

        database_tuple_repository_tests.main();

        native_to_drift_migration_test.main();
      },
    );
