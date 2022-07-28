# Test

```shell
flutter test ../test ../integration_test
```

## Generate mocks

```shell
cd ../
flutter pub run build_runner build
```

## Unit test

```shell
flutter test ../test/unit
```

`Unit test`はドメインで完結するテストのみを記述する  
ドメインは概念なので何にも依存しない  
つまり単一の言語で記述する

## Widget test

```shell
flutter test ../test/widget
```

`Widget test`はUIのテストを記述する  
UIはFlutterに依存する  
UIにフォーカスしたテストを記述するため、Flutter以外の依存はすべてモックする

## Integration test

```shell
flutter test ../integration_test
```

`Integrration test`では実端末でのテストを記述する  
端末とは、Android、Windowsなど実際にアプリケーションが動作するプラットフォーム全般を指す
シナリオテストも兼ねる実装とする

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
flutter test ../test ../integration_test --coverage
```