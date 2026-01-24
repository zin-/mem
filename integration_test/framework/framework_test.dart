import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/logger/log.dart';
import 'package:mem/features/logger/log_service.dart';
import 'database_repository_tests.dart' as database_repository_tests;

const _name = "Framework test";

void main() => group(
      _name,
      () {
        LogService(
          level: Level.verbose,
          enableSimpleLog:
              const bool.fromEnvironment('CICD', defaultValue: false),
        );

        database_repository_tests.main();
      },
    );
