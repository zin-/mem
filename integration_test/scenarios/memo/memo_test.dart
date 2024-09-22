import 'package:flutter_test/flutter_test.dart';
import 'package:mem/logger/log.dart';
import 'package:mem/logger/log_service.dart';

import 'list_scenarios.dart' as list_scenarios;
import 'detail_scenarios.dart' as detail_scenarios;

const _scenarioName = 'Memo scenario';

void main() => group(': $_scenarioName', () {
      LogService.initialize(
        Level.verbose,
        const bool.fromEnvironment('CICD', defaultValue: false),
      );

      list_scenarios.main();
      detail_scenarios.main();
    });
