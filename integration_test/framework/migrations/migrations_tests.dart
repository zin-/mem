import 'package:flutter_test/flutter_test.dart';

import 'native_to_drift_tests.dart' as native_to_drifts;

const _name = "Migrations test";

void main() => group(
      _name,
      () {
        native_to_drifts.main();
      },
    );
