import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testEdgeScenario();
}

const _scenarioName = "Edge scenario";

// Edge scenarioには、特殊な状況でしか発生しない想定外の挙動を防ぐためのテストを定義する
void testEdgeScenario() => group(
      ": $_scenarioName",
      () {
        // 運用上、想定外の挙動がない場合には0件となる
        // テストが1件もないと失敗になるため成功するテストを定義しておく
        test("Success", () => expect(true, true));
      },
    );
