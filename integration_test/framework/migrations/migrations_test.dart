import 'package:flutter_test/flutter_test.dart';

import 'native_to_drift_migration_test.dart' as native_to_drift_migration_test;

const _name = "Migrations test";

void main() => group(
      _name,
      () {
        native_to_drift_migration_test.main();
      },
    );
