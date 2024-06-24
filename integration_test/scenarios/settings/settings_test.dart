import 'package:flutter_test/flutter_test.dart';

import 'backup_scenario.dart' as backup_scenario;
import 'settings_scenario.dart' as settings_scenario;

const _testName = 'Settings test';

void main() => group(
      _testName,
      () {
        settings_scenario.main();
        backup_scenario.main();
      },
    );
