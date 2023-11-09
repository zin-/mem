#!/bin/bash

# もしCI環境なら引数を求める。
if [ $# -ne 1 ] && [ "$CI" = "true" ]; then
  echo "引数にデバイス名を指定してください。"
  exit 1
fi

#ディレクトリ移動
cd "$(dirname "$0")/.." || exit 1

if [ "$CI" = true ]; then
  # CI環境のテスト実行
  flutter test integration_test --dart-define=CICD=true --coverage --machine -d "$1" | tee >(grep "^{" | grep "}$" >temp_report.log)
else
  if [ $# -eq 1 ]; then
    #デバイス名が設定されているなら
    flutter test integration_test --coverage -d "$1"
  else
    #デバイス名が設定されていないなら
    flutter test integration_test --coverage
  fi
  #カバレッジの出力
  genhtml coverage/lcov.info -o coverage/integration_html >/dev/null
  #開く
  open "file://$(pwd)/coverage/integration_html/index.html"
fi
