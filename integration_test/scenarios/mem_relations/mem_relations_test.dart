import 'package:flutter_test/flutter_test.dart';
import 'package:mem/features/logger/log.dart';
import 'package:mem/features/logger/log_service.dart';

import 'mem_relations_scenarios.dart' as mem_relations_scenarios;

const _scenarioName = 'Mem relations scenario';

void main() => group(': $_scenarioName', () {
      LogService(
        level: Level.verbose,
        enableSimpleLog:
            const bool.fromEnvironment('CICD', defaultValue: false),
      );

      mem_relations_scenarios.main();
    });
