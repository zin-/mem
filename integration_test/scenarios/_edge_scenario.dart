import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/database/database_manager.dart';

import '../_helpers.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  DatabaseManager(onTest: true);

  testEdgeScenario();
}

void testEdgeScenario() => group(
      'Edge scenario',
      () {
        setUp(() async => await clearDatabase());

        group(
          'Edge scenario',
          () {},
        );
      },
    );
