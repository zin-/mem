import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mem/framework/database/database_manager.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  DatabaseManager(onTest: true);

  testEdgeScenario();
}

void testEdgeScenario() => group(
      'Edge scenario',
      () {
        group(
          'Edge scenario',
          () {},
        );
      },
    );
