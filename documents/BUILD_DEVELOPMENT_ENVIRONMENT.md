# DEVELOPMENT_ENVIRONMENT

## Install Flutter

基本的には[公式のGet Started](https://docs.flutter.dev/get-started/install)通りで良い

大きく変わっていなければ(macOSでは)、 1.zipファイルのダウンロード、2.解凍、配置、3.PATH追加が必要

完了したら
```zsh
flutter doctor -v
```
で状況が確認できる

初回実行時は`Android license status unknown.`となっているはずだが、これには`Android sdkmanager`が必要なので、以降の項目で行う

## Run scripts

```shell
dart pub global activate rps
```

## For test

### For integration test on Chrome

- Download and install chromedriver
  - [Reference](https://docs.flutter.dev/testing/integration-tests#running-in-a-browser)

## For Windows

Enable developer mode for Windows

- [Reference](https://docs.microsoft.com/ja-jp/windows/apps/get-started/enable-your-device-for-development)
