import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testEdgeScenario();
}

const _scenarioName = "Edge scenario";

void testEdgeScenario() => group(": $_scenarioName", () {});
