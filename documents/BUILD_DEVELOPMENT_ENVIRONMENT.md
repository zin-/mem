# DEVELOPMENT_ENVIRONMENT

## Install Flutter

基本的には[公式](https://docs.flutter.dev/get-started/install)通りで良い

大きく変わっていなければ(macOSでは)、 1.zipファイルのダウンロード、2.解凍、配置、3.PATH追加が必要

完了したら
```shell
cd ../
flutter doctor -v
```
で状況が確認できる

初回実行時は`Android license status unknown.`となっているはずだが、これには`Android sdkmanager`が必要なので、以降の項目で行う

## Android SDK manager

ここも基本は[公式](https://docs.flutter.dev/get-started/install/macos/mobile-android)など（ここではmacOS用）通りで良い

Android Studio（IntelliJ IDEAでもほぼ同様）からAndroid SDK managerを起動しても良いし、手動（CLIやファイルダウンロード）で頑張っても良い  
（CLIからの場合、適切なディレクトリ構成になってくれない場合があるので注意。進めていたら一応エラーが出たはず）

完了したら
```shell
cd ../
flutter doctor --android-licenses
```
でライセンスに同意したらOK

## IDE

ここではIntelliJ IDEAで開発をするものとする（他のIDEを使うようになったら追記する）

### Flutter plugin

PluginsからFlutterをインストール

めちゃくちゃエラーになってるはずだけど一旦気にしない

### Flutter SDK

Flutter SDKのpathをIDEに教えてあげる必要がある  
設定のFlutterから、[先ほどインストールしたFlutter](#Install-Flutter)のpathを指定する

完了したら
```shell
cd ../
flutter pub get
```
で依存関係を解決する

## Run scripts

```shell
cd ../
dart pub global activate rps
```

## For test

### For integration test on Chrome

- Download and install chromedriver
  - [Reference](https://docs.flutter.dev/testing/integration-tests#running-in-a-browser)

## For Windows

Enable developer mode for Windows

- [Reference](https://docs.microsoft.com/ja-jp/windows/apps/get-started/enable-your-device-for-development)
