#!/bin/bash

if [ $# -ne 1 ] && [ "$CI" = "true" ]; then
  echo "Invalid arguments. Argument 1 must be device name."
  exit 1
fi

cd "$(dirname "$0")/.." || exit 1

if [ "$CI" = true ]; then
  flutter test integration_test --dart-define=CICD=true --coverage --machine -d "$1" | tee >(grep "^{" | grep "}$" >temp_report.log)
else
  if [ $# -eq 1 ]; then
    flutter test integration_test --coverage -d "$1"
  else
    flutter test integration_test --coverage
  fi
  genhtml coverage/lcov.info -o coverage/integration_html >/dev/null
  open "file://$(pwd)/coverage/integration_html/index.html"
fi
