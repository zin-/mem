# CI/CD

Continuous Integration and Continuous Delivery(/Deployment)

## CI

変更を統合(Integrate)する際に、継続的(Continuous)に品質を担保するための仕組み

## Integrate

~~統合は、基本的にはコードやスクリプトの定義になるためgitの機能で達成される~~
競合(Conflict)が発生した際に、人が解決した場合達成されない可能性がある  
これを達成するために、コードチェックやテストの実行が必要

## Continuous

継続的に行なうには、人が関わるべきではないため自動化する

「コードチェックやテストの実行」のために必要な処理を定義し、これを実装する

これらの処理は、ローカル環境でも（自動化するかはさておき）実行できる方法にしたい
ローカル開発環境の構築手順となるためでもある

問題を検知した際の報告も必要

## 必要な処理

### コードチェック

- コードの依存解決
  - 依存ライブラリの解決
  - 依存ファイルの生成
    - アイコン
    - 言語(Localization/l10n)ファイル
    - テスト用のモック(Mocks)
    - その他、ライブラリによって自動生成する必要があるファイル
- チェック対象
  - アプリケーションコード
  - テストコード

### テスト

- 端末に閉じたテスト
  - Medium test
  - 対象プラットフォーム
    - Android, Windows, Web, MacOSなど（Flutterが動作するすべての環境で実行したい）
      - 現時点ではAndroidとWindowsのみ
- ドメインに閉じたテスト
  - Small test
- すべてに開いたテスト
  - Large test
  - 現時点では、プラットフォームに閉じたDBやAPIへのアクセスしか行っていないため実装しない
    - 端末外のシステムにアクセスするように拡張したら検討する

### 環境

コードチェックもテストも同じ環境でそれぞれ行い、環境は複数用意したい

具体的には以下

- プラットフォーム
  - Windows
  - MacOS
  - Ubuntu
- Flutter version
  - stable
  - canary
- Device
  - Android
    - OS version
    - 何があるか知らない
  - Windows
    - latest
  - MacOS
  - iPhone
  - iPad
  - Ubuntu

## CD

現時点では、どこかに届けるということを目的としていないため実装しない

https://github.com/zin-/mem/issues/272