# Test

```shell
flutter test ../test ../integration_test/app_test.dart
```

## Generate mocks

```shell
cd ../
flutter pub run build_runner build
```

## Unit test

`Unit test`はドメインで完結するテストのみを記述する  
ドメインは概念なので、外部のライブラリなどには依存しない  
つまり単一の言語で記述される

```shell
flutter test ../test/unit
```

## Widget test

`Widget test`はUIのテストを記述する  
UIはFlutterに依存する  
UIにフォーカスしたテストを記述するため、Flutter以外の依存はすべてモックする

```shell
flutter test ../test/widget
```

## Integration test

`Integrration test`では実端末でのテストを記述する
端末とは、Android、Windowsなど実際にアプリケーションが動作するプラットフォーム全般を指す
シナリオテストも兼ねる実装とする

```shell
flutter test ../integration_test/app_test.dart
```

### Basic scenario

アプリが満たすべき基本的な挙動を記述する
機能が動作することを確認し、恒久的に担保するために追加される

### Edge scenario

TODO naming

基本的な動作以外で、特殊な（とはいってもありうる）操作をした場合の挙動を記述する
挙動に違和感が発生した際に、正しい挙動の確認と恒久的な担保のために追加される

### On real platform

```shell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
```

テスト端末を選択する

### On Web browser

```shell
chromedriver --port=4444
```

```shell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d web-server
```

## With coverage

```shell
flutter test ../test ../integration_test/app_test.dart --coverage
```