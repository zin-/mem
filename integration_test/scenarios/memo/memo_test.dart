import 'package:flutter_test/flutter_test.dart';

import 'list_scenarios.dart' as list_scenarios;
import 'detail_scenarios.dart' as detail_scenarios;

const _scenarioName = "Memo scenario";

void main() => group(
      _scenarioName,
      () {
        list_scenarios.main();
        detail_scenarios.main();
      },
    );
