import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/logger/log.dart';
import 'package:mem/features/logger/log_service.dart';

import 'list_scenarios.dart' as list_scenarios;
import 'detail_scenarios.dart' as detail_scenarios;

const _scenarioName = 'Memo scenario';

void main() => group(': $_scenarioName', () {
      LogService(
        level: Level.verbose,
        enableSimpleLog:
            const bool.fromEnvironment('CICD', defaultValue: false),
      );

      list_scenarios.main();
      detail_scenarios.main();
    });
