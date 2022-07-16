# Test

## Unit test

```shell
flutter test ../test/unit
```

## Widget test

```shell
flutter test ../test/widget
```

## Integration test

```shell
flutter test ../integration_test
```

### On real platform

```shell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
```

### On Web browser

```shell
chromedriver --port=4444
```

FIXME IntelliJ IDEA上でこのファイルから実行しようとするとパスが通せておらず、実行できない（別で起動することで動作はする）

```shell
flutter drive --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart -d web-server
```